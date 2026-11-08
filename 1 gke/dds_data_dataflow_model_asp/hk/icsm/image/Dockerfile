### STAGE 1 - MAVEN BUILDER
FROM nexus3.systems.uk.hsbc:18096/com/hsbc/group/itid/es/mw/java/azuljava-jdk-ubuntu-21:latest AS builder
USER root
WORKDIR /build
ARG NEXUS_USER
ARG NEXUS_USER_PW
RUN echo "machine nexus302.systems.uk.hsbc:8081/nexus/repository/apt-proxy-ubuntu-n3p_q/" > /etc/apt/auth.conf \
    && echo "login $NEXUS_USER" >> /etc/apt/auth.conf \
    && echo "password $NEXUS_USER_PW" >> /etc/apt/auth.conf \     // 将 Nexus APT 仓库地址、用户名和密码写入 /etc/apt/auth.conf
    && chmod 600 /etc/apt/auth.conf \
    && apt-get update \           
    && apt-get install -y maven \                         // /etc/apt/auth.conf 作用就是让 apt-get 在访问 Nexus APT 仓库时使用提供的用户名和密码进行身份验证，从而能够成功下载依赖包。 
    && rm -f /etc/apt/auth.conf \
    && rm -rf /var/lib/apt/lists/*
COPY pom.xml .
RUN mkdir -p /root/.m2 \                                  // 生成配置目录
    && printf '<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">
    <mirrors>
        <mirror>
            <id>nexus</id>                               // 这里的 <id>nexus</id> 是 Maven 配置中这个仓库镜像的标识符
            <name>Nexus Maven Proxy</name>               // 供人阅读的名称，主要用于说明这个镜像是什么
            <url>https://nexus302.systems.uk.hsbc:8081/nexus/repository/maven-hsbc-central-proxy-n3p/</url>
            <mirrorOf>*</mirrorOf>
        </mirror>                          //让 Maven 从 Nexus 镜像获取所有仓库依赖
    </mirrors>
    <servers>
        <server>
            <id>nexus</id>
            <username><![CDATA[$NEXUS_USER]]></username>
            <password><![CDATA[$NEXUS_USER_PW]]></password>
        </server>
    </servers>
</settings>' > /root/.m2/settings.xml \   
    && mvn clean install -s /root/.m2/settings.xml -DskipTests \       //install --编译、打包，并将产物安装到本地 Maven 仓库,-s指定使用刚写入的 Maven 配置。
    && rm -f /root/.m2/settings.xml

### STAGE 2 - DATAFLOW RUNTIME
FROM gcr.io/dataflow-templates-base/python312-template-launcher-base AS template_launcher
FROM europe-west1-artifactregistry.gcr.io/google.com/dataflow-containers/worker/v1beta/beam_python3.12_sdk:2.72.0 AS build_base
FROM asia-east2-docker.pkg.dev/hsbc-11505776-ddshk-dev/ar-repo/python:3.12
USER root
RUN mkdir -p /template/jars
COPY requirements.txt /template/
COPY --from=template_launcher /opt/google/dataflow/python_template_launcher /opt/google/dataflow/
COPY --from=build_base /opt/apache/beam /opt/apache/beam
COPY output_table_schema.json /template/
COPY error_table_schema.json /template/
COPY --from=builder /build/jars/ /template/jars/
# Accept Nexus credentials as build arguments
ARG NEXUS_USER
ARG NEXUS_USER_PW
# Inject credentials into /etc/apt/auth.conf for APT repository authentication
RUN mkdir -p /etc/apt
RUN echo "machine nexus302.systems.uk.hsbc:8081/nexus/repository/apt-proxy-ubuntu-n3p_q/" > /etc/apt/auth.conf \
    && echo "login $NEXUS_USER" >> /etc/apt/auth.conf \
    && echo "password $NEXUS_USER_PW" >> /etc/apt/auth.conf \
    && chmod 600 /etc/apt/auth.conf
RUN pip install \
--no-cache-dir \
-r \
/template/requirements.txt

RUN apt-get update && \
    apt-get install -y \
    openjdk-17-jre \                                          // openjdk-17-jre 是 OpenJDK 17 的 Java 运行环境（JRE）软件包,它提供运行 Java 程序所需的 Java 虚拟机（JVM）和运行库
    && rm -f /etc/apt/auth.conf \
    && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"                           // 设置 Java 17 的安装目录。  让容器里可以直接运行 java、javac、jar、keytool 等命令，并且优先使用 $JAVA_HOME/bin 下的 Java 版本。如果这里找不到命令，再继续去原来的 PATH 目录里找。
ENV FLEX_TEMPLATE_PYTHON_PY_FILE="/template/main.py"     // 指定 Flex Template 使用的 Python 主程序。
ENV RUN_PYTHON_SDK_IN_DEFAULT_ENVIRONMENT=1
RUN rm -f /etc/localtime
RUN ln -s /usr/share/zoneinfo/UTC /etc/localtime      //将系统本地时区设置为 UTC
RUN sed -i "s/\//g" /etc/timezone
# RUN chmod +x /opt/google/dataflow/python_template_launcher
# ENV PIP_NO_DEPS=True
COPY main.py /template/
ENTRYPOINT ["/opt/apache/beam/boot"]        //容器启动时运行 Beam 的启动脚本












/*
nexus3.systems.uk.hsbc:18096/com/hsbc/group/itid/es/mw/java/azuljava-jdk-ubuntu-21:latest
gcr.io/dataflow-templates-base/python312-template-launcher-base
europe-west1-artifactregistry.gcr.io/google.com/dataflow-containers/worker/v1beta/beam_python3.12_sdk:2.72.0
asia-east2-docker.pkg.dev/hsbc-11505776-ddshk-dev/ar-repo/python:3.12

Java builder 镜像
    -> 编译生成 JAR

Dataflow launcher 镜像
    -> 提供 Flex Template 启动器

Beam SDK 镜像
    -> 提供 Apache Beam 运行环境

HSBC Python 3.12 镜像
    -> 作为最终运行镜像
*/




FROM nexus3.systems.uk.hsbc:18096/com/hsbc/group/itid/es/mw/java/azuljava-jdk-ubuntu-21:latest AS builder
FROM gcr.io/dataflow-templates-base/python312-template-launcher-base AS template_launcher
FROM europe-west1-artifactregistry.gcr.io/google.com/dataflow-containers/worker/v1beta/beam_python3.12_sdk:2.72.0 AS build_base
FROM asia-east2-docker.pkg.dev/hsbc-11505776-ddshk-dev/ar-repo/python:3.12
这四个怎么协作的？聚集核心，给口语化，60s之内 的回答, 前后要有逻辑


这四个镜像用的是多阶段构建，就像搭积木——前三个提供“零件”，最后一个负责“总装”。
第一个（Azul JDK 21） 是Java编译器。如果你用Java写Dataflow管道，它负责把Java代码编译成JAR包；用Python的话它就是个陪跑的。
第二个（Launcher） 是点火开关。它提供python_template_launcher，Dataflow提交任务时第一个跑的就是它，负责接收参数、启动整个作业。
第三个（Beam SDK Worker） 是干活引擎。它提供/opt/apache/beam/boot启动脚本，工作节点靠它真正执行你的数据处理代码。
第四个（私有Python 3.12） 是最终的运行环境。它把前面生成的JAR、Launcher和Beam SDK都整合进来，安装依赖，设置环境变量，确保整个Dataflow作业能顺利启动和运行。=
运行时顺序： 最终镜像启动 → 先跑Launcher点火 → 生成管道图交给Dataflow → 工作节点跑Beam boot → 执行你的处理逻辑。