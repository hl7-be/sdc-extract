## What we tried

(test performed with opat Questionnaire(Response))
- Step 1:
    - extracting with tiro test server: successful
    - extracting with ehealth server: successful after a minor change:
        - The questionnaire contains fields like "%questionnaire.descendants().where(linkId = 'H1_SkinRash').code". The fhirpath element '%questionnaire' was not valid. After removing all occurences the extract method was succesful
- Step 2:
    - There were two issues with the tiro generated Bundle
        - An Observation contained a valueCodeableConcept and a valueQuantity, one was removed
        - A DiagnosticReport was generated without a code field. One was added
        - After these changes we managed to upload the bundle to a Google FHIR Server (without referential integrity)
    - The ehealth test server generated bundle had some more errors (because we removed the fhirpath elements probably)
    - The ehealth server gave an error on the referential integrity, as the Bundle contained literal references that did not exist
- Step 3:
    - On the Google FHIR server we used, the results were available.

## What we found

- We think the extract method on a fhir server can be very useful, and eliminates software devs having to try and convert QR's to Observations themselves
- The definitions do need to be perfect, if they miss a mandatory field for example, the transaction Bundle will contain an invalid resource
- (small) The scripts seemed to expect mac line endings, so there were some small changes necessary to make them work on windows


## Open questions or follow-up ideas

- Some struggles at the start with connection issues caused a slow start, with more time the tests in 'bonus-data-transporter.md' seem interesting, as they raise some interesting questions.