#!/usr/bin/env groovy
def call(Map stepParams = [:]) {
    def pipelineValuesMap = [:]
    def selectedPipelineValuesPath = ''
    def new_pipelineValuesFileName = "${stepParams.gcpProject}/pipelineValues.yaml"
    def pipelineValuesFileName = stepParams.pipelineFile ?: 'pipelineValuesOverride.yaml'
    def configRepoDir = stepParams.configRepoDir ?: ''
    def centralizedProjectFile = ''
    def centralizedProjectMapFile = ''

    if (configRepoDir?.trim()) {
        centralizedProjectFile = "${configRepoDir}/${stepParams.gcpProject}/pipelineValues.yaml"
        centralizedProjectMapFile = "${configRepoDir}/projects/pipelineValuesByProject.yaml"
    }

    if ( fileExists(file: new_pipelineValuesFileName) ) {
        selectedPipelineValuesPath = new_pipelineValuesFileName
        pipelineValuesMap = readYaml(file: selectedPipelineValuesPath)
    }
    else {
        if ( fileExists(file: pipelineValuesFileName) ) {
            selectedPipelineValuesPath = pipelineValuesFileName
            pipelineValuesMap = readYaml(file: selectedPipelineValuesPath)
        }
        else if (centralizedProjectFile && fileExists(file: centralizedProjectFile)) {
            selectedPipelineValuesPath = centralizedProjectFile
            pipelineValuesMap = readYaml(file: selectedPipelineValuesPath)
        }
        else if (centralizedProjectMapFile && fileExists(file: centralizedProjectMapFile)) {
            def centralizedMap = readYaml(file: centralizedProjectMapFile) ?: []
            def selectedProjectMap = centralizedMap["${stepParams.gcpProject}"]
            if (selectedProjectMap instanceof java.util.LinkedHashMap) {
                selectedPipelineValuesPath = centralizedProjectMapFile + "#${stepParams.gcpProject}"
                pipelineValuesMap = selectedProjectMap
            }
        }
    }

    def globalValuesMap = readYaml(file: copyResource(srcPath: 'infra/params/globalValues.yaml')) ?: [:]
    def appConfig = joinMaps(joinMaps(globalValuesMap, pipelineValuesMap), stepParams)

    appConfig += [
        gitUrl: "${env.GIT_URL}".substring(0, "${env.GIT_URL}".length() - 4),
    ]

    if (env.DEBUG == 'true') {
        if (selectedPipelineValuesPath) {
            echo "Selected pipeline values source: ${selectedPipelineValuesPath}"
        } else {
            echo "No project-specific pipeline values file found. Only global values and runtime params will be used."
        }
        echo "appConfig content: ${appConfig}"
    }

    return appConfig
}

def joinMaps(LinkedHashMap map1, LinkedHashMap map2) {
    map2.collect {
        if (it.value instanceof java.util.LinkedHashMap) {
            def mapName = it.key
            if (!map1."${mapName}") {
                map1 << [(mapName): [] ]
                map1."${mapName}" = map2."${mapName}"
            } else {
                def newMap = mergeHashMap(map1."${mapName}", map2."${mapName}")
                map1."${mapName}" << newMap
            }
        } else if (it.value instanceof java.util.ArrayList) {
            def listName = it.key
            if (!map1."${listName}") {
                map1 << [(listName): [] ]
            }
            map2."${listName}".collect { k ->
                if (!map1."${listName}".find { it == k }) {
                    map1."${listName}" << k
                }
            }
        } else {
            map1.put(it.key, it.value)
        }
    }
    return map1
}

def mergeHashMap(LinkedHashMap map1, LinkedHashMap map2) {
    def resultMap = map1.clone()
    map2.collect { k, v ->
        if (!(map1.get(k) != null)) {
            resultMap[k] = v
        } else {
            if (map1.get(k) != null)
            && (map1.get(k) instanceof java.util.LinkedHashMap)
            && (v instanceof java.util.LinkedHashMap)
            {
                resultMap[k] = mergeHashMap(map1.get(k, [:]), v)
            } else {
                resultMap[k] = v
            }
        }
    }
    return resultMap
}