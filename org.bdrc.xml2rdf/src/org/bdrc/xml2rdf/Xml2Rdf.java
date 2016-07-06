package org.bdrc.xml2rdf;

import java.io.File;
import java.io.FileOutputStream;

import tr.com.srdc.ontmalizer.XML2OWLMapper;
import tr.com.srdc.ontmalizer.XSD2OWLMapper;

public class Xml2Rdf {

	public Xml2Rdf() {
		// TODO Auto-generated constructor stub
	}

	public static void main(String[] args) {
		String schemaDir = args[0] + (args[0].endsWith("/") ? "" : "/");
		String schema = args[1];
		String inDocDir = args[2] + (args[2].endsWith("/") ? "" : "/");
		String outDocDir = args[3] + (args[3].endsWith("/") ? "" : "/");;

		String schemaPath = schemaDir + schema;
		// Convert XML schema to OWL ontology.
		XSD2OWLMapper mapping = new XSD2OWLMapper(new File(schemaPath + ".xsd"));
		mapping.setObjectPropPrefix("");
		mapping.setDataTypePropPrefix("");
		mapping.convertXSD2OWL();

		// Serialize the ontology to a file for later use.
		try {
			File ontf = new File(schemaPath + ".n3");
			ontf.getParentFile().mkdirs();
			FileOutputStream onts = new FileOutputStream(ontf);
			mapping.writeOntology(onts, "N3");
			onts.close();
		} catch (Exception e) {
			e.printStackTrace();
		}


		// convert each doc in inDocDir and write to outDocDir

		File inDocs = new File(inDocDir);
		File outDocs = new File(outDocDir);
		if (! inDocs.isDirectory()) {
			System.err.println(inDocDir + " not a directory");
			System.exit(1);
		}
		if (! outDocs.isDirectory()) {
			outDocs.mkdirs();
			if (! outDocs.isDirectory()) {
				System.err.println(outDocDir + " not a directory");
				System.exit(2);
			}
		}

		String[] inDocNames = inDocs.list();

		for (int i = 0; i < inDocNames.length; i++) {
			String inDoc = inDocNames[i];
			if (inDoc.endsWith(".xml")) {
				System.err.println("Converting " + inDoc);
				File inf = new File(inDocDir + inDoc);
				XML2OWLMapper generator = new XML2OWLMapper(inf, inDoc.replace(".xml", ""), mapping);
				generator.convertXML2OWL();

				// Serialize the RDF data model to a file.
				try{
					File outf = new File(outDocDir + inDoc.replace(".xml", ".n3"));
					FileOutputStream outs = new FileOutputStream(outf);
					generator.writeModel(outs, "N3");
					outs.close();
				} catch (Exception e){
					e.printStackTrace();
				}
			}
		}
	}
}