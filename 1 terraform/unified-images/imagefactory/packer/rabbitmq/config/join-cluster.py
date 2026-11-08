python
  
#!/usr/bin/env python3

import argparse
import re
import socket
import subprocess
import sys
import time
import typing as t

PARAM_SECRET_HELP: t.Text = "RabbitMQ credential secret name (kept for backward compatibility)."
PARAM_HOSTS_HELP: t.Text = "List of RabbitMQ cluster hosts separated by ':'"

cli_arg_parser: argparse.ArgumentParser = argparse.ArgumentParser(
    description="Join RabbitMQ node to an existing cluster"
)
cli_arg_parser.add_argument("--secret", type=t.Text, help=PARAM_SECRET_HELP)
cli_arg_parser.add_argument("--hosts", type=t.Text, help=PARAM_HOSTS_HELP)
cli_arg_parser.add_argument("--nodes", type=t.Text, help=argparse.SUPPRESS)
args: argparse.Namespace = cli_arg_parser.parse_args()


def log(message: str) -> None:
    print(message, flush=True)


def run_cmd(cmd: t.List[str], check: bool = False) -> subprocess.CompletedProcess:
    log(f'Running: {" ".join(cmd)}')
    result = subprocess.run(cmd, text=True, capture_output=True)
    if result.stdout:
        log(result.stdout.strip())
    if result.stderr:
        log(result.stderr.strip())
    if check and result.returncode != 0:
        raise subprocess.CalledProcessError(
            result.returncode, cmd, output=result.stdout, stderr=result.stderr
        )
    return result


def get_hostname_fqdn() -> t.Text:
    try:
        host = socket.getfqdn().strip().lower()
        if host:
            return host
    except Exception:
        pass

    result = run_cmd(["hostname", "-f"])
    host = (result.stdout or "").strip().lower()
    if host:
        return host

    host = socket.gethostname().strip().lower()
    if host:
        return host

    raise RuntimeError("Unable to determine current hostname")


def canonical_host(host_or_node: t.Text) -> t.Text:
    value = host_or_node.strip().lower()
    if value.startswith("rabbit@"):
        value = value[len("rabbit@"):]
    if not value:
        return value

    try:
        fqdn = socket.getfqdn(value).strip().lower()
        return fqdn or value
    except Exception:
        return value


def short_host(host_or_node: t.Text) -> t.Text:
    normalized = canonical_host(host_or_node)
    return normalized.split(".", 1)[0]


def to_node_name(host_or_node: t.Text) -> t.Text:
    return f"rabbit@{canonical_host(host_or_node)}"


def normalize_hosts(host_list_raw: t.Text) -> t.List[t.Text]:
    seen: t.Set[str] = set()
    normalized_hosts: t.List[str] = []

    for token in host_list_raw.split(":"):
        raw = token.strip()
        if not raw:
            continue
        host = canonical_host(raw)
        if host and host not in seen:
            seen.add(host)
            normalized_hosts.append(host)

    return normalized_hosts


def build_cluster_hosts(host_list_raw: t.Text, current_host: t.Text) -> t.List[t.Text]:
    hosts = normalize_hosts(host_list_raw)
    current_canonical = canonical_host(current_host)
    if current_canonical not in hosts:
        hosts.append(current_canonical)

    deduped = sorted(dict.fromkeys(hosts))
    if not deduped:
        raise ValueError("No cluster hosts were provided for seed election")
    return deduped


def elect_seed_host(cluster_hosts: t.List[t.Text]) -> t.Text:
    if not cluster_hosts:
        raise ValueError("No cluster hosts were provided for seed election")
    # deterministic: short hostname first, then full FQDN as tie-breaker
    return sorted(cluster_hosts, key=lambda host: (short_host(host), host))[0]


def build_candidate_nodes(
    cluster_hosts: t.List[t.Text], current_host: t.Text, seed_host: t.Text
) -> t.List[t.Text]:
    current_short = short_host(current_host)
    seed_short = short_host(seed_host)

    if current_short == seed_short:
        return []

    candidates: t.List[str] = [to_node_name(seed_host)]
    for host in cluster_hosts:
        host_short = short_host(host)
        if host_short in {current_short, seed_short}:
            continue
        node_name = to_node_name(host)
        if node_name not in candidates:
            candidates.append(node_name)

    return candidates


def parse_running_nodes(cluster_status_output: str) -> t.List[str]:
    match = re.search(
        r"running_nodes\s*,\s*\[(.*?)\]",
        cluster_status_output,
        flags=re.IGNORECASE | re.DOTALL,
    )
    if not match:
        return []

    node_chunk = match.group(1).strip()
    if not node_chunk:
        return []

    parsed_nodes: t.List[str] = []
    for token in node_chunk.split(","):
        item = token.strip().strip("'\"")
        if item:
            parsed_nodes.append(item)
    return parsed_nodes


def is_already_clustered_with_seed(current_host: str, seed_host: str) -> bool:
    result = run_cmd(["rabbitmqctl", "cluster_status"])
    if result.returncode != 0:
        return False

    running_nodes = parse_running_nodes(result.stdout or "")
    if not running_nodes:
        return False

    current_short = short_host(current_host)
    seed_short = short_host(seed_host)

    running_shorts = {short_host(node) for node in running_nodes}
    has_seed = seed_short in running_shorts
    has_other = any(host_short != current_short for host_short in running_shorts)

    log(f"Detected running nodes: {running_nodes}")
    return has_seed and has_other


def ensure_app_running() -> bool:
    status_result = run_cmd(["rabbitmqctl", "status"])
    if status_result.returncode == 0:
        log("RabbitMQ app is already running")
        return True

    start_result = run_cmd(["rabbitmqctl", "start_app"])
    if start_result.returncode != 0:
        log("Could not start RabbitMQ app")
        return False
    return True


def stop_app_if_needed() -> bool:
    stop_result = run_cmd(["rabbitmqctl", "stop_app"])
    if stop_result.returncode == 0:
        return True

    combined = f"{stop_result.stdout}\n{stop_result.stderr}".lower()
    # Tolerate "already stopped"/similar states
    if "not running" in combined or "already" in combined:
        log("RabbitMQ app appears already stopped; continuing")
        return True

    log("Could not stop RabbitMQ app")
    return False


def should_reset_from_join_error(output: str) -> bool:
    lower = output.lower()
    reset_markers = (
        "inconsistent_cluster",
        "timeout_waiting_for_tables",
        "mnesia",
        "database",
        "already_member",
        "cluster_not_formed",
    )
    return any(marker in lower for marker in reset_markers)


def join_cluster(host_list_raw: t.Text) -> None:
    current_host = canonical_host(get_hostname_fqdn())
    current_node = to_node_name(current_host)

    try:
        cluster_hosts = build_cluster_hosts(host_list_raw, current_host)
        seed_host = elect_seed_host(cluster_hosts)
        candidate_nodes = build_candidate_nodes(cluster_hosts, current_host, seed_host)
    except ValueError as err:
        log(f"[ERROR] {err}")
        sys.exit(1)

    log(f"Current host: {current_host}")
    log(f"Current node: {current_node}")
    log(f"Elected seed host: {seed_host}")
    log(f"Cluster hosts: {cluster_hosts}")
    log(f"Join candidates (seed first): {candidate_nodes}")

    is_seed = short_host(current_host) == short_host(seed_host)

    if is_seed:
        log("This node is the elected seed host; ensuring app is running and waiting for peers to join.")
        sleep_seconds = 100
        log(f"Seed node sleeping {sleep_seconds}s to give peer nodes time to start before clustering.")
        time.sleep(sleep_seconds)
        if not ensure_app_running():
            sys.exit(1)
        return

    if not candidate_nodes:
        log("No candidate cluster nodes provided for non-seed node")
        sys.exit(1)

    # Idempotent shortcut: if already clustered with seed, do not disrupt.
    if is_already_clustered_with_seed(current_host, seed_host):
        log("Node is already clustered with seed; skipping join/reset flow.")
        if not ensure_app_running():
            sys.exit(1)
        return

    if not stop_app_if_needed():
        sys.exit(1)

    join_ok = False
    reset_performed = False
    attempts = 10

    for attempt in range(1, attempts + 1):
        log(f"Join attempt {attempt}/{attempts}")

        for target in candidate_nodes:
            join_result = run_cmd(["rabbitmqctl", "join_cluster", target])
            if join_result.returncode == 0:
                log(f"Successfully joined cluster via {target}")
                join_ok = True
                break

        combined_output = f"{join_result.stdout}\n{join_result.stderr}"
        if (not reset_performed) and should_reset_from_join_error(combined_output):
            log("Join error suggests stale/inconsistent state; performing one-time reset and retrying.")
            reset_result = run_cmd(["rabbitmqctl", "reset"])
            if reset_result.returncode != 0:
                log("Could not reset RabbitMQ node before joining")
                sys.exit(1)
            reset_performed = True

        if join_ok:
            break

        sleep_seconds = min(10 + attempt * 5, 45)
        log(f"Join attempt failed; retrying in {sleep_seconds}s")
        time.sleep(sleep_seconds)

    if not ensure_app_running():
        sys.exit(1)

    status_result = run_cmd(["rabbitmqctl", "cluster_status"])
    if status_result.returncode == 0:
        running_nodes = parse_running_nodes(status_result.stdout or "")
        if running_nodes:
            log("Running nodes: " + ", ".join(running_nodes))

    if not join_ok:
        log("Unable to join cluster after retries")
        sys.exit(1)


def main(param_hosts: t.Text) -> None:
    join_cluster(param_hosts)


if __name__ == "__main__":
    hosts = args.hosts or args.nodes
    if not hosts:
        cli_arg_parser.error("one of --hosts or --nodes is required")
    main(t.cast(t.Text, hosts))