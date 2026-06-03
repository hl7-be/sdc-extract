import org.hl7.fhir.r4.context.SimpleWorkerContext;
import org.hl7.fhir.r4.elementmodel.Element;
import org.hl7.fhir.r4.elementmodel.Manager;
import org.hl7.fhir.r4.elementmodel.Manager.FhirFormat;
import org.hl7.fhir.r4.formats.JsonParser;
import org.hl7.fhir.r4.model.StructureDefinition;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;

public class Spike {
    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.err.println("usage: Spike <path-to-StructureDefinition.json> [path-to-instance.json]");
            System.exit(2);
        }
        String sdPath = args[0];
        String instancePath = args.length > 1 ? args[1] : null;

        // --- 1. Empty worker context, load the SD into it
        SimpleWorkerContext ctx = SimpleWorkerContext.fromNothing();
        StructureDefinition sd;
        try (FileInputStream in = new FileInputStream(sdPath)) {
            sd = (StructureDefinition) new JsonParser().parse(in);
        }
        ctx.cacheResource(sd);
        System.out.println("[ok] Loaded SD: kind=" + sd.getKind() + " url=" + sd.getUrl());

        // --- 2. THE BET: build an Element root from this kind=logical SD
        Element root;
        try {
            root = Manager.build(ctx, sd);
        } catch (Throwable t) {
            System.out.println("[FAIL] Manager.build threw for kind=logical SD:");
            t.printStackTrace(System.out);
            System.exit(1);
            return;
        }
        System.out.println("[ok] Manager.build(ctx, sd) returned Element: name=" + root.getName()
                + " type=" + root.getType() + " fhirType=" + root.fhirType());

        // --- 3. Compose the empty Element to JSON (proves the write/serialize path works)
        ByteArrayOutputStream out1 = new ByteArrayOutputStream();
        try {
            Manager.compose(ctx, root, out1, FhirFormat.JSON, null, null);
        } catch (Throwable t) {
            System.out.println("[FAIL] Manager.compose threw on empty root:");
            t.printStackTrace(System.out);
            System.exit(1);
            return;
        }
        System.out.println("[ok] Manager.compose on empty root:");
        System.out.println(out1.toString());

        // --- 4. Attempt to set a real primitive leaf path
        // From the SD differential: opat-continuous-infusion-questionnaire.nursingAssessment.storage.medicationStorageRemarks
        try {
            // Auto-create parents by setting child values along the chain
            root.setChildValue("nursingAssessment", null);
            Element nursingAssessment = root.getNamedChild("nursingAssessment");
            if (nursingAssessment != null) {
                nursingAssessment.setChildValue("storage", null);
                Element storage = nursingAssessment.getNamedChild("storage");
                if (storage != null) {
                    storage.setChildValue("medicationStorageRemarks", "Stored at 4C");
                    System.out.println("[ok] Set medicationStorageRemarks via setChildValue chain");
                } else {
                    System.out.println("[warn] storage child was not created");
                }
            } else {
                System.out.println("[warn] nursingAssessment child was not created");
            }
        } catch (Throwable t) {
            System.out.println("[warn] setChildValue chain failed (expected — see fallback): " + t);
        }

        ByteArrayOutputStream out2 = new ByteArrayOutputStream();
        Manager.compose(ctx, root, out2, FhirFormat.JSON, null, null);
        System.out.println("[ok] Manager.compose after setChildValue attempt:");
        System.out.println(out2.toString());

        // --- 5. Bonus: try parsing the existing logical-model instance and round-tripping it
        if (instancePath != null) {
            try {
                org.hl7.fhir.r4.elementmodel.JsonParser p = new org.hl7.fhir.r4.elementmodel.JsonParser(ctx);
                Element parsed;
                try (FileInputStream in = new FileInputStream(instancePath)) {
                    parsed = p.parse(in);
                }
                System.out.println("[ok] element-model JsonParser parsed instance: fhirType=" + parsed.fhirType());
                ByteArrayOutputStream out3 = new ByteArrayOutputStream();
                Manager.compose(ctx, parsed, out3, FhirFormat.JSON, null, null);
                System.out.println("[ok] Round-tripped instance JSON:");
                System.out.println(out3.toString());
            } catch (Throwable t) {
                System.out.println("[warn] parse/round-trip of instance failed:");
                t.printStackTrace(System.out);
            }
        }
    }
}
