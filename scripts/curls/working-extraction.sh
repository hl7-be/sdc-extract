curl --location 'https://hapi.fhir-testserver.be/fhir/1000112/QuestionnaireResponse/$extract?api_key=REDACTED' \
--header 'Accept: application/fhir+json' \
--header 'Content-Type: application/fhir+json' \
--data '{
    "resourceType": "QuestionnaireResponse",
    "contained": [
        {
            "resourceType": "Questionnaire",
            "id": "inline-q",
            "contained": [
                {
                    "resourceType": "Patient",
                    "id": "patient-placeholder",
                    "meta": {
                        "tag": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/v3-ObservationValue",
                                "code": "SUBSETTED",
                                "display": "subsetted"
                            }
                        ]
                    },
                    "identifier": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v2-0203",
                            "value": "UNKNOWN"
                        }
                    ],
                    "name": [
                        {
                            "family": "Unknown",
                            "given": [
                                "Patient"
                            ]
                        }
                    ]
                }
            ],
            "title": "OPAT - continu infuus",
            "status": "active",
            "item": [
                {
                    "linkId": "Verpleegkundigassessment",
                    "text": "Verpleegkundig assessment",
                    "type": "group",
                    "item": [
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
                                    "valueCanonical": "http://hl7.org/fhir/StructureDefinition/Observation"
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.status"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCode": "final"
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.category"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCodeableConcept": {
                                                "coding": [
                                                    {
                                                        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                                        "code": "survey",
                                                        "display": "Survey"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.subject"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueReference": {
                                                "reference": "#patient-placeholder"
                                            }
                                        }
                                    ]
                                }
                            ],
                            "linkId": "Bewaring",
                            "text": "Bewaring",
                            "type": "group",
                            "item": [
                                {
                                    "linkId": "A1_Bewaring",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Zijn er opmerkingen of bezorgdheden omtrent de (correcte) thuisbewaring van de medicatie?",
                                    "type": "choice",
                                    "required": true,
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "710977001",
                                                "display": "Safe storage of medication"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "424363005",
                                                "display": "Improper storage of medication"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "A2_BewaringSpecifieer",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.note.text",
                                    "text": "> Indien opmerkingen of bezorgdheid: specifieer",
                                    "type": "string",
                                    "enableWhen": [
                                        {
                                            "question": "A1_Bewaring",
                                            "operator": "=",
                                            "answerCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "424363005",
                                                "display": "Improper storage of medication"
                                            }
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
                                    "valueCanonical": "http://hl7.org/fhir/StructureDefinition/Observation"
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.status"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCode": "final"
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.category"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCodeableConcept": {
                                                "coding": [
                                                    {
                                                        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                                        "code": "survey",
                                                        "display": "Survey"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.subject"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueReference": {
                                                "reference": "#patient-placeholder"
                                            }
                                        }
                                    ]
                                }
                            ],
                            "linkId": "Voorbereidingmedicatietoediening",
                            "text": "Voorbereiding medicatietoediening",
                            "type": "group",
                            "item": [
                                {
                                    "linkId": "B1_MedicatieVolledigOpgelost",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "De medicatie werd volledig opgelost tot een heldere oplossing zonder zichtbare deeltjes",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "B2_IndienNeeContact",
                                    "text": "> Indien nee: gelieve contact op te nemen met het zorgteam in het ziekenhuis",
                                    "type": "display",
                                    "enableWhen": [
                                        {
                                            "question": "B1_MedicatieVolledigOpgelost",
                                            "operator": "=",
                                            "answerCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "extension": [
                                        {
                                            "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-unit",
                                            "valueCoding": {
                                                "system": "http://unitsofmeasure.org",
                                                "code": "g",
                                                "display": "g"
                                            }
                                        },
                                        {
                                            "url": "http://fhir.wgk.com/StructureDefinition/wgk-ext-helptext",
                                            "valueString": "Enkel in te vullen indien continu infuus"
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.system"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueUri": "http://unitsofmeasure.org"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.code"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueCode": "g"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.unit"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueString": "g"
                                                }
                                            ]
                                        }
                                    ],
                                    "linkId": "B3_GewichtVolleInfusor",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.value",
                                    "text": "Gewicht van volle Infusor net voor nieuwe toediening",
                                    "type": "decimal",
                                    "required": true
                                },
                                {
                                    "extension": [
                                        {
                                            "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-unit",
                                            "valueCoding": {
                                                "system": "http://unitsofmeasure.org",
                                                "code": "g",
                                                "display": "g"
                                            }
                                        },
                                        {
                                            "url": "http://fhir.wgk.com/StructureDefinition/wgk-ext-helptext",
                                            "valueString": "Enkel in te vullen indien continu infuus"
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.system"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueUri": "http://unitsofmeasure.org"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.code"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueCode": "g"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.unit"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueString": "g"
                                                }
                                            ]
                                        }
                                    ],
                                    "linkId": "B4_GewichtLegeInfusor",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.value",
                                    "text": "Gewicht bij afkoppelen van lege infusor",
                                    "type": "decimal",
                                    "required": true
                                },
                                {
                                    "linkId": "B5_BijkomendeObservatie",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.note.text",
                                    "text": "Bijkomende observatie:(indien van toepassing)",
                                    "type": "string"
                                }
                            ]
                        },
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
                                    "valueCanonical": "http://hl7.org/fhir/StructureDefinition/Observation"
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.status"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCode": "final"
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.category"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCodeableConcept": {
                                                "coding": [
                                                    {
                                                        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                                        "code": "survey",
                                                        "display": "Survey"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.subject"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueReference": {
                                                "reference": "#patient-placeholder"
                                            }
                                        }
                                    ]
                                }
                            ],
                            "linkId": "Medicatietoediening",
                            "text": "Medicatietoediening",
                            "type": "group",
                            "item": [
                                {
                                    "linkId": "C1_ToedieningCorrect",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Kon de medicatie exact volgens de procedure worden toegediend  (er waren geen afwijkingen)?",
                                    "type": "choice",
                                    "required": true,
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "C2_SpecifieerNee",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.note.text",
                                    "text": "> Indien neen: specifieer",
                                    "type": "string",
                                    "enableWhen": [
                                        {
                                            "question": "C1_ToedieningCorrect",
                                            "operator": "=",
                                            "answerCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
                                    "valueCanonical": "http://hl7.org/fhir/StructureDefinition/Observation"
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.status"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCode": "final"
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.category"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCodeableConcept": {
                                                "coding": [
                                                    {
                                                        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                                        "code": "vital-signs",
                                                        "display": "Vital Signs"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.subject"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueReference": {
                                                "reference": "#patient-placeholder"
                                            }
                                        }
                                    ]
                                }
                            ],
                            "linkId": "Vitaleparameters",
                            "text": "Vitale parameters",
                            "type": "group",
                            "item": [
                                {
                                    "extension": [
                                        {
                                            "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-unit",
                                            "valueCoding": {
                                                "system": "http://unitsofmeasure.org",
                                                "code": "Cel",
                                                "display": "°C"
                                            }
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.system"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueUri": "http://unitsofmeasure.org"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.code"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueCode": "Cel"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.unit"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueString": "°C"
                                                }
                                            ]
                                        }
                                    ],
                                    "linkId": "D1_Temperatuur",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.value",
                                    "text": "Lichaamstemperatuur:",
                                    "type": "decimal",
                                    "required": true
                                },
                                {
                                    "extension": [
                                        {
                                            "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-unit",
                                            "valueCoding": {
                                                "system": "http://unitsofmeasure.org",
                                                "code": "{beats}/min",
                                                "display": "bpm"
                                            }
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.system"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueUri": "http://unitsofmeasure.org"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.code"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueCode": "{beats}/min"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.unit"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueString": "bpm"
                                                }
                                            ]
                                        }
                                    ],
                                    "linkId": "D2_Pols",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.value",
                                    "text": "Pols:",
                                    "type": "decimal"
                                },
                                {
                                    "extension": [
                                        {
                                            "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-unit",
                                            "valueCoding": {
                                                "system": "http://unitsofmeasure.org",
                                                "code": "mm[Hg]",
                                                "display": "mmHg"
                                            }
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.system"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueUri": "http://unitsofmeasure.org"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.code"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueCode": "mm[Hg]"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.unit"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueString": "mmHg"
                                                }
                                            ]
                                        }
                                    ],
                                    "linkId": "D3_BloeddrukSystolisch",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.value",
                                    "text": "Bloeddruk - systolisch",
                                    "type": "decimal"
                                },
                                {
                                    "extension": [
                                        {
                                            "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-unit",
                                            "valueCoding": {
                                                "system": "http://unitsofmeasure.org",
                                                "code": "mm[Hg]",
                                                "display": "mmHg"
                                            }
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.system"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueUri": "http://unitsofmeasure.org"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.code"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueCode": "mm[Hg]"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                            "extension": [
                                                {
                                                    "url": "definition",
                                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.unit"
                                                },
                                                {
                                                    "url": "fixed-value",
                                                    "valueString": "mmHg"
                                                }
                                            ]
                                        }
                                    ],
                                    "linkId": "D4_BloeddrukDiastolisch",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueQuantity.value",
                                    "text": "Bloeddruk - diastolisch",
                                    "type": "decimal"
                                }
                            ]
                        },
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
                                    "valueCanonical": "http://hl7.org/fhir/StructureDefinition/Observation"
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.status"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCode": "final"
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.category"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCodeableConcept": {
                                                "coding": [
                                                    {
                                                        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                                        "code": "exam",
                                                        "display": "Exam"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.subject"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueReference": {
                                                "reference": "#patient-placeholder"
                                            }
                                        }
                                    ]
                                }
                            ],
                            "linkId": "Observatieverbandinsteekplaats",
                            "text": "Observatie verband insteekplaats",
                            "type": "group",
                            "item": [
                                {
                                    "linkId": "E1_VerbandObservatie",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Observatie verband insteekplaats",
                                    "type": "choice",
                                    "required": true,
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "17621005",
                                                "display": "Normal (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "263654008",
                                                "display": "Abnormal (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "E2_IndienAfwijkendSpecifieer",
                                    "text": "> Indien '\''afwijkend'\'': specifieer",
                                    "type": "display",
                                    "enableWhen": [
                                        {
                                            "question": "E1_VerbandObservatie",
                                            "operator": "=",
                                            "answerCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "263654008",
                                                "display": "Abnormal (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "E3_Bloederig",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Bloederig",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "E4_Etterig",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Etterig",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "E5_Los",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Los",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "E6_Sereus",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Sereus",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "E7_Vochtig",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Vochtig",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "E8_Andere",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.note.text",
                                    "text": "Andere: (indien van toepassing)",
                                    "type": "string"
                                }
                            ]
                        },
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
                                    "valueCanonical": "http://hl7.org/fhir/StructureDefinition/Observation"
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.status"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCode": "final"
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.category"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCodeableConcept": {
                                                "coding": [
                                                    {
                                                        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                                        "code": "exam",
                                                        "display": "Exam"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.subject"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueReference": {
                                                "reference": "#patient-placeholder"
                                            }
                                        }
                                    ]
                                }
                            ],
                            "linkId": "Observatieinsteekplaats",
                            "text": "Observatie insteekplaats",
                            "type": "group",
                            "item": [
                                {
                                    "linkId": "F1_InsteekplaatsObservatie",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Observatie insteekplaats",
                                    "type": "choice",
                                    "required": true,
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "17621005",
                                                "display": "Normal (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "263654008",
                                                "display": "Abnormal (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "F2_IndienAfwijkendSpecifieer",
                                    "text": "> Indien '\''afwijkend'\'': specifieer",
                                    "type": "display",
                                    "enableWhen": [
                                        {
                                            "question": "F1_InsteekplaatsObservatie",
                                            "operator": "=",
                                            "answerCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "263654008",
                                                "display": "Abnormal (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "F3_Blaarvorming",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Blaarvorming",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "F4_Rood",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Rood",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "F5_Haematoom",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Haematoom",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "F6_Etter",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Etter",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "F7_Korstvorming",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Korstvorming",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "F8_Zwelling",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Zwelling",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "F9_Extravasatie",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Extravasatie/infiltratie",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "F10_Andere",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.note.text",
                                    "text": "Andere: (indien van toepassing)",
                                    "type": "string"
                                }
                            ]
                        },
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
                                    "valueCanonical": "http://hl7.org/fhir/StructureDefinition/Observation"
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.status"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCode": "final"
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.category"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCodeableConcept": {
                                                "coding": [
                                                    {
                                                        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                                        "code": "exam",
                                                        "display": "Exam"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.subject"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueReference": {
                                                "reference": "#patient-placeholder"
                                            }
                                        }
                                    ]
                                }
                            ],
                            "linkId": "Observatiekatheter",
                            "text": "Observatie katheter",
                            "type": "group",
                            "item": [
                                {
                                    "linkId": "G1_KatheterObservatie",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Observatie katheter",
                                    "type": "choice",
                                    "required": true,
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "17621005",
                                                "display": "Normal (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "263654008",
                                                "display": "Abnormal (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "G2_IndienAfwijkendSpecifieer",
                                    "text": "> Indien '\''afwijkend'\'': specifieer",
                                    "type": "display",
                                    "enableWhen": [
                                        {
                                            "question": "G1_KatheterObservatie",
                                            "operator": "=",
                                            "answerCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "263654008",
                                                "display": "Abnormal (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "G2b_KatheterType",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Kies kathetertype",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "52124006",
                                                "display": "Central venous catheter"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "445085009",
                                                "display": "Tunneled central venous catheter"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "1344705000",
                                                "display": "Midline catheter"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "398176008",
                                                "display": "Peripherally inserted central catheter"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "423954007",
                                                "display": "Peripheral catheter"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "G3_Bloedaspiratie",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Bloedaspiratie",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "36203004",
                                                "display": "Easy"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "52925006",
                                                "display": "Difficult"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "385671000",
                                                "display": "Unsuccessful"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "G4_Infusie",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Infusie",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "36203004",
                                                "display": "Easy"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "52925006",
                                                "display": "Difficult"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "385671000",
                                                "display": "Unsuccessful"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "G5_BeschadigdeKatheter",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Beschadigde katheter",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373066001",
                                                "display": "Yes (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "373067005",
                                                "display": "No (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "G6_Andere",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.note.text",
                                    "text": "Andere: (indien van toepassing)",
                                    "type": "string"
                                }
                            ]
                        },
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
                                    "valueCanonical": "http://hl7.org/fhir/StructureDefinition/Observation"
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.status"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCode": "final"
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.category"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueCodeableConcept": {
                                                "coding": [
                                                    {
                                                        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                                        "code": "survey",
                                                        "display": "Survey"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                },
                                {
                                    "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                                    "extension": [
                                        {
                                            "url": "definition",
                                            "valueUri": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.subject"
                                        },
                                        {
                                            "url": "fixed-value",
                                            "valueReference": {
                                                "reference": "#patient-placeholder"
                                            }
                                        }
                                    ]
                                }
                            ],
                            "linkId": "Nevenwerkingen",
                            "text": "Nevenwerkingen",
                            "type": "group",
                            "item": [
                                {
                                    "linkId": "H1_Huiduitslag",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Huiduitslag",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H2_Jeuk",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Jeuk",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H3_BlarenOfHuidloslaten",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Blaren/loslaten van de huid",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H4_Misselijkheid",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Misselijkheid",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H5_Braken",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Braken",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H6_Diarree",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Diarree",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H7_Obstipatie",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Obstipatie",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H8_VerminderdeEetlust",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Verminderde eetlust",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H9_PijnBijToediening",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Pijn bij toediening",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H10_PijnAlgemeen",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Pijn (algemeen)",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H11_Moe",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Moe",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H12_Rillingen",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Rillingen",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H13_Candidiasis",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Candidiase (schimmelinfectie)",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H14_Gewrichtspijn",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Gewrichtspijn",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H15_Ademhalingsproblemen",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Ademhalingsproblemen",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H16_ZwellingGezichtTong",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.valueCodeableConcept",
                                    "text": "Zwelling gezicht/tong",
                                    "type": "choice",
                                    "answerOption": [
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "2667000",
                                                "display": "Absent (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "255604002",
                                                "display": "Mild (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "6736007",
                                                "display": "Moderate (qualifier value)"
                                            }
                                        },
                                        {
                                            "valueCoding": {
                                                "system": "http://snomed.info/sct",
                                                "code": "24484000",
                                                "display": "Severe (qualifier value)"
                                            }
                                        }
                                    ]
                                },
                                {
                                    "linkId": "H17_AndereObservaties",
                                    "definition": "http://hl7.org/fhir/StructureDefinition/Observation#Observation.note.text",
                                    "text": "Is er andere symptoomlast of zijn er andere relevante klinische en/of psychosociale observaties? \n(gelieve bij klinische bezorgdheid contact te nemen met het zorgteam in het ziekenhuis)",
                                    "type": "string"
                                }
                            ]
                        }
                    ]
                },
                {
                    "extension": [
                        {
                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract",
                            "valueCanonical": "http://hl7.org/fhir/StructureDefinition/DiagnosticReport"
                        },
                        {
                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                            "extension": [
                                {
                                    "url": "definition",
                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/DiagnosticReport#DiagnosticReport.status"
                                },
                                {
                                    "url": "fixed-value",
                                    "valueCode": "final"
                                }
                            ]
                        },
                        {
                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                            "extension": [
                                {
                                    "url": "definition",
                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/DiagnosticReport#DiagnosticReport.category"
                                },
                                {
                                    "url": "fixed-value",
                                    "valueCodeableConcept": {
                                        "coding": [
                                            {
                                                "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                                                "code": "OTH",
                                                "display": "Other"
                                            }
                                        ]
                                    }
                                }
                            ]
                        },
                        {
                            "url": "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue",
                            "extension": [
                                {
                                    "url": "definition",
                                    "valueUri": "http://hl7.org/fhir/StructureDefinition/DiagnosticReport#DiagnosticReport.subject"
                                },
                                {
                                    "url": "fixed-value",
                                    "valueReference": {
                                        "reference": "#patient-placeholder"
                                    }
                                }
                            ]
                        }
                    ],
                    "linkId": "Kwaliteitsopvolging",
                    "text": "(Kwaliteits)opvolging",
                    "type": "group",
                    "item": [
                        {
                            "linkId": "I1_OpmerkingenAanmelding",
                            "definition": "http://hl7.org/fhir/StructureDefinition/DiagnosticReport#DiagnosticReport.conclusion",
                            "text": "Zijn er opmerkingen of bezorgdheden omtrent de aanmelding van deze patient, de gegevensdeling vanuit het ziekenhuis, de communicatie door en het contact met het ziekenhuis, de beschikbaarheid van de medicatie en materialen, of andere aspecten van de transmurale samenwerking rond thuishospitalisatie OPAT, we vragen je graag ze met ons te delen. Alvast dank.",
                            "type": "string"
                        }
                    ]
                }
            ]
        }
    ],
  "meta": {
        "profile": [
            "http://hl7.org/fhir/4.0/StructureDefinition/QuestionnaireResponse"
        ],
        "tag": [
            {
                "code": "lformsVersion: 41.1.0"
            }
        ]
    },
    "status": "completed",
    "authored": "2026-04-21T07:49:58.595Z",
    "item": [
        {
            "linkId": "Verpleegkundigassessment",
            "text": "Verpleegkundig assessment",
            "item": [
                {
                    "linkId": "Bewaring",
                    "text": "Bewaring",
                    "item": [
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "710977001",
                                        "display": "Safe storage of medication"
                                    }
                                }
                            ],
                            "linkId": "A1_Bewaring",
                            "text": "Zijn er opmerkingen of bezorgdheden omtrent de (correcte) thuisbewaring van de medicatie?"
                        }
                    ]
                },
                {
                    "linkId": "Voorbereidingmedicatietoediening",
                    "text": "Voorbereiding medicatietoediening",
                    "item": [
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373066001",
                                        "display": "Yes (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "B1_MedicatieVolledigOpgelost",
                            "text": "De medicatie werd volledig opgelost tot een heldere oplossing zonder zichtbare deeltjes"
                        },
                        {
                            "answer": [
                                {
                                    "valueDecimal": 208
                                }
                            ],
                            "linkId": "B3_GewichtVolleInfusor",
                            "text": "Gewicht van volle Infusor net voor nieuwe toediening"
                        },
                        {
                            "answer": [
                                {
                                    "valueDecimal": 167
                                }
                            ],
                            "linkId": "B4_GewichtLegeInfusor",
                            "text": "Gewicht bij afkoppelen van lege infusor"
                        },
                        {
                            "answer": [
                                {
                                    "valueString": "Niet volledig leeg owv aangehangen om 13.00 uur"
                                }
                            ],
                            "linkId": "B5_BijkomendeObservatie",
                            "text": "Bijkomende observatie:(indien van toepassing)"
                        }
                    ]
                },
                {
                    "linkId": "Medicatietoediening",
                    "text": "Medicatietoediening",
                    "item": [
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373066001",
                                        "display": "Yes (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "C1_ToedieningCorrect",
                            "text": "Kon de medicatie exact volgens de procedure worden toegediend  (er waren geen afwijkingen)?"
                        }
                    ]
                },
                {
                    "linkId": "Vitaleparameters",
                    "text": "Vitale parameters",
                    "item": [
                        {
                            "answer": [
                                {
                                    "valueDecimal": 36.3
                                }
                            ],
                            "linkId": "D1_Temperatuur",
                            "text": "Lichaamstemperatuur:"
                        },
                        {
                            "answer": [
                                {
                                    "valueDecimal": 71
                                }
                            ],
                            "linkId": "D2_Pols",
                            "text": "Pols:"
                        },
                        {
                            "answer": [
                                {
                                    "valueDecimal": 114
                                }
                            ],
                            "linkId": "D3_BloeddrukSystolisch",
                            "text": "Bloeddruk - systolisch"
                        },
                        {
                            "answer": [
                                {
                                    "valueDecimal": 67
                                }
                            ],
                            "linkId": "D4_BloeddrukDiastolisch",
                            "text": "Bloeddruk - diastolisch"
                        }
                    ]
                },
                {
                    "linkId": "Observatieverbandinsteekplaats",
                    "text": "Observatie verband insteekplaats",
                    "item": [
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "17621005",
                                        "display": "Normal (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "E1_VerbandObservatie",
                            "text": "Observatie verband insteekplaats"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "E3_Bloederig",
                            "text": "Bloederig"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "E4_Etterig",
                            "text": "Etterig"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "E5_Los",
                            "text": "Los"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "E6_Sereus",
                            "text": "Sereus"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "E7_Vochtig",
                            "text": "Vochtig"
                        }
                    ]
                },
                {
                    "linkId": "Observatieinsteekplaats",
                    "text": "Observatie insteekplaats",
                    "item": [
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "263654008",
                                        "display": "Abnormal (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "F1_InsteekplaatsObservatie",
                            "text": "Observatie insteekplaats"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "F3_Blaarvorming",
                            "text": "Blaarvorming"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373066001",
                                        "display": "Yes (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "F4_Rood",
                            "text": "Rood"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "F5_Haematoom",
                            "text": "Haematoom"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "F6_Etter",
                            "text": "Etter"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "F7_Korstvorming",
                            "text": "Korstvorming"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "F8_Zwelling",
                            "text": "Zwelling"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "F9_Extravasatie",
                            "text": "Extravasatie/infiltratie"
                        }
                    ]
                },
                {
                    "linkId": "Observatiekatheter",
                    "text": "Observatie katheter",
                    "item": [
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "17621005",
                                        "display": "Normal (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "G1_KatheterObservatie",
                            "text": "Observatie katheter"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "36203004",
                                        "display": "Easy"
                                    }
                                }
                            ],
                            "linkId": "G3_Bloedaspiratie",
                            "text": "Bloedaspiratie"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "36203004",
                                        "display": "Easy"
                                    }
                                }
                            ],
                            "linkId": "G4_Infusie",
                            "text": "Infusie"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "373067005",
                                        "display": "No (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "G5_BeschadigdeKatheter",
                            "text": "Beschadigde katheter"
                        }
                    ]
                },
                {
                    "linkId": "Nevenwerkingen",
                    "text": "Nevenwerkingen",
                    "item": [
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H1_Huiduitslag",
                            "text": "Huiduitslag"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H2_Jeuk",
                            "text": "Jeuk"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H3_BlarenOfHuidloslaten",
                            "text": "Blaren/loslaten van de huid"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H4_Misselijkheid",
                            "text": "Misselijkheid"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H5_Braken",
                            "text": "Braken"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H6_Diarree",
                            "text": "Diarree"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H7_Obstipatie",
                            "text": "Obstipatie"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "255604002",
                                        "display": "Mild (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H8_VerminderdeEetlust",
                            "text": "Verminderde eetlust"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H9_PijnBijToediening",
                            "text": "Pijn bij toediening"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H10_PijnAlgemeen",
                            "text": "Pijn (algemeen)"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "6736007",
                                        "display": "Moderate (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H11_Moe",
                            "text": "Moe"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H12_Rillingen",
                            "text": "Rillingen"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "24484000",
                                        "display": "Severe (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H13_Candidiasis",
                            "text": "Candidiase (schimmelinfectie)"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H14_Gewrichtspijn",
                            "text": "Gewrichtspijn"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "255604002",
                                        "display": "Mild (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H15_Ademhalingsproblemen",
                            "text": "Ademhalingsproblemen"
                        },
                        {
                            "answer": [
                                {
                                    "valueCoding": {
                                        "system": "http://snomed.info/sct",
                                        "code": "2667000",
                                        "display": "Absent (qualifier value)"
                                    }
                                }
                            ],
                            "linkId": "H16_ZwellingGezichtTong",
                            "text": "Zwelling gezicht/tong"
                        },
                        {
                            "answer": [
                                {
                                    "valueString": "Pte heeft last van droge mond"
                                }
                            ],
                            "linkId": "H17_AndereObservaties",
                            "text": "Is er andere symptoomlast of zijn er andere relevante klinische en/of psychosociale observaties? \n(gelieve bij klinische bezorgdheid contact te nemen met het zorgteam in het ziekenhuis)"
                        }
                    ]
                }
            ]
        }
    ],
    "questionnaire": "#inline-q"
}'