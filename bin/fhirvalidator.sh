#! /bin/zsh

java -cp ${JAVA_CLASSPATH} org.hl7.fhir.validation.ValidatorCli $@
