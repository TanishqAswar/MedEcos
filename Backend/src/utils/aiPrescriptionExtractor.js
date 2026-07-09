const { GoogleGenerativeAI } = require('@google/generative-ai');

/**
 * Extracts structured medicine doses from a prescription image buffer or URL using Gemini Vision AI.
 * @param {Buffer} fileBuffer - The image or PDF buffer
 * @param {string} mimeType - e.g. 'image/jpeg', 'image/png', 'application/pdf'
 * @returns {Promise<Object>} Extracted prescription data
 */
async function extractPrescriptionWithAI(fileBuffer, mimeType = 'image/jpeg') {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        console.warn('GEMINI_API_KEY not set. Returning template structure for verification.');
        return getFallbackExtraction();
    }

    try {
        const genAI = new GoogleGenerativeAI(apiKey);
        const model = genAI.getGenerativeModel({
            model: 'gemini-1.5-flash',
            generationConfig: {
                responseMimeType: 'application/json',
            }
        });

        const prompt = `You are an expert medical AI specializing in reading handwritten and printed medical prescriptions.
Analyze this prescription image/document and extract EVERY prescribed medicine listed into a structured JSON array.
Important: A prescription often contains multiple medicines. Carefully inspect every line and return all medicines found.
Return ONLY valid JSON matching this schema:
{
  "doctorName": "Doctor's name if visible, else 'Scanned Doctor'",
  "diagnosis": "Diagnosis or complaint if visible, else 'General Prescription'",
  "medicines": [
    {
      "name": "Full medicine name with strength (e.g. Paracetamol 500mg, Amoxicillin 500mg)",
      "dosage": "Dosage unit (e.g. 1 Tablet, 10 ml)",
      "timing": "Standardized timing: must be one or combination of 'Morning', 'Afternoon', 'Evening', 'Night' (e.g. 'Morning, Night' for BD/twice daily)",
      "context": "Must be one of: 'After Food', 'Before Food', 'With Food'",
      "durationDays": number of days (integer, e.g. 5, 7, 0 if ongoing),
      "instruction": "Special instructions if any"
    }
  ]
}`;

        const imagePart = {
            inlineData: {
                data: fileBuffer.toString('base64'),
                mimeType: mimeType
            }
        };

        const result = await model.generateContent([prompt, imagePart]);
        const responseText = result.response.text();
        const parsed = JSON.parse(responseText);

        return {
            success: true,
            doctorName: parsed.doctorName || 'Scanned Doctor',
            diagnosis: parsed.diagnosis || 'General Prescription',
            medicines: Array.isArray(parsed.medicines) ? parsed.medicines : []
        };
    } catch (error) {
        console.error('Gemini Vision OCR extraction failed:', error.message);
        return getFallbackExtraction();
    }
}

function getFallbackExtraction() {
    return {
        success: false,
        doctorName: 'Scanned Prescription',
        diagnosis: 'Prescription Scan',
        medicines: [
            {
                name: 'Amoxicillin 500mg',
                dosage: '1 Tablet',
                timing: 'Morning, Night',
                context: 'After Food',
                durationDays: 5,
                instruction: 'Take after meals'
            },
            {
                name: 'Paracetamol 650mg',
                dosage: '1 Tablet',
                timing: 'Morning, Afternoon, Night',
                context: 'After Food',
                durationDays: 3,
                instruction: 'Take when having fever'
            }
        ]
    };
}

module.exports = {
    extractPrescriptionWithAI
};
