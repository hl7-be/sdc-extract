import org.hl7.fhir.r4.context.SimpleWorkerContext;
import org.hl7.fhir.r4.elementmodel.Element;
import org.hl7.fhir.r4.elementmodel.Manager;
import org.hl7.fhir.r4.elementmodel.Manager.FhirFormat;
import org.hl7.fhir.r4.formats.JsonParser;
import org.hl7.fhir.r4.model.StructureDefinition;
import org.hl7.fhir.utilities.npm.NpmPackage;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;

public class SpikeComplex {
    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.err.println("usage: SpikeComplex <r4-core-folder> <complex-lm-sd.json>");
            System.exit(2);
        }
        String r4CoreFolder = args[0];
        String sdPath = args[1];

        // --- 1. Load FHIR r4 core into a real IWorkerContext
        SimpleWorkerContext ctx = SimpleWorkerContext.fromPackage(NpmPackage.fromFolder(r4CoreFolder));
        System.out.println("[ok] Loaded r4 core into IWorkerContext");

        // --- 2. Load the synthetic LM SD that uses CodeableConcept + Quantity
        StructureDefinition sd;
        try (FileInputStream in = new FileInputStream(sdPath)) {
            sd = (StructureDefinition) new JsonParser().parse(in);
        }

        ctx.cacheResource(sd);
        System.out.println("[ok] Cached LM SD: " + sd.getUrl()
                + " (snapshot elements=" + sd.getSnapshot().getElement().size() + ")");

        // --- 3. Build the Element from a kind=logical SD that has complex types
        Element root;
        try {
            root = Manager.build(ctx, sd);
        } catch (Throwable t) {
            System.out.println("[FAIL] Manager.build threw on complex-type LM:");
            t.printStackTrace(System.out);
            System.exit(1);
            return;
        }
        System.out.println("[ok] Manager.build OK. fhirType=" + root.fhirType());

        // --- 5. Set a CodeableConcept: ComplexLM.code.coding[0].{system,code,display}
        try {
            root.setChildValue("code", null);
            Element code = root.getNamedChild("code");
            code.setChildValue("text", "Lab observation");

            // To add a coding, create a child element of type Coding under code.coding
            // setChildValue creates a primitive child, which is wrong for coding.
            // Use makeProperty to create a complex child.
            org.hl7.fhir.r4.model.Base codingBase = code.makeProperty("coding".hashCode(), "coding");
            if (codingBase instanceof Element) {
                Element coding = (Element) codingBase;
                coding.setChildValue("system", "http://loinc.org");
                coding.setChildValue("code", "12345-6");
                coding.setChildValue("display", "Some lab");
                System.out.println("[ok] Built code.coding via makeProperty");
            } else {
                System.out.println("[warn] makeProperty returned non-Element: " + codingBase.getClass());
            }
        } catch (Throwable t) {
            System.out.println("[FAIL] could not build CodeableConcept:");
            t.printStackTrace(System.out);
        }

        // --- 6. Set a Quantity
        try {
            org.hl7.fhir.r4.model.Base qtyBase = root.makeProperty("qty".hashCode(), "qty");
            if (qtyBase instanceof Element) {
                Element qty = (Element) qtyBase;
                qty.setChildValue("value", "5.4");
                qty.setChildValue("unit", "mmol/L");
                qty.setChildValue("system", "http://unitsofmeasure.org");
                qty.setChildValue("code", "mmol/L");
                System.out.println("[ok] Built qty Quantity via makeProperty");
            }
        } catch (Throwable t) {
            System.out.println("[FAIL] could not build Quantity:");
            t.printStackTrace(System.out);
        }

        // --- 7. Add multiple repeating notes (cardinality 0..*)
        try {
            org.hl7.fhir.r4.model.Base n1 = root.makeProperty("note".hashCode(), "note");
            if (n1 instanceof Element) ((Element) n1).setValue("first note");
            org.hl7.fhir.r4.model.Base n2 = root.makeProperty("note".hashCode(), "note");
            if (n2 instanceof Element) ((Element) n2).setValue("second note");
            System.out.println("[ok] Added 2x repeating note via makeProperty");
        } catch (Throwable t) {
            System.out.println("[FAIL] repeating element failed:");
            t.printStackTrace(System.out);
        }

        // --- 8. Compose
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Manager.compose(ctx, root, out, FhirFormat.JSON, null, null);
        System.out.println("[ok] Compose output:");
        System.out.println(out.toString());
    }
}
