#! /bin/zsh

# java -cp ${JAVA_CLASSPATH} org.hl7.fhir.validation.ValidatorCli $@
java -jar ${FHIR_VALIDATOR_JAR} $@
