require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { extractPrescriptionWithAI } = require('./src/utils/aiPrescriptionExtractor');

const LOCAL_PRESCRIPTION_PATH = 'C:\\Users\\TANISHQ\\Downloads\\Screenshot 2026-07-09 161847.png';

async function runTest() {
    console.log('='.repeat(60));
    console.log('  MedEcos Gemini Vision AI Prescription Extractor - TEST');
    console.log('='.repeat(60));

    if (!process.env.GEMINI_API_KEY) {
        console.error('\n❌ GEMINI_API_KEY not found in .env!');
        process.exit(1);
    }
    console.log(`\n🔑 API Key: ${process.env.GEMINI_API_KEY.slice(0, 12)}...${process.env.GEMINI_API_KEY.slice(-4)} (loaded)`);

    if (!fs.existsSync(LOCAL_PRESCRIPTION_PATH)) {
        console.error(`\n❌ File not found: ${LOCAL_PRESCRIPTION_PATH}`);
        process.exit(1);
    }

    const buffer = fs.readFileSync(LOCAL_PRESCRIPTION_PATH);
    const ext = path.extname(LOCAL_PRESCRIPTION_PATH).toLowerCase();
    const mimeType = ext === '.png' ? 'image/png' : ext === '.pdf' ? 'application/pdf' : 'image/jpeg';
    console.log(`\n📄 Loaded: ${path.basename(LOCAL_PRESCRIPTION_PATH)}`);
    console.log(`   Size: ${buffer.length} bytes | Type: ${mimeType}`);

    console.log('\n🤖 Sending to Gemini Vision AI (gemini-2.0-flash)...');
    console.log('   Analyzing handwritten prescription...\n');

    const startTime = Date.now();
    const result = await extractPrescriptionWithAI(buffer, mimeType);
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);

    console.log('='.repeat(60));
    console.log(`${result.success ? '✅' : '⚠️ '} Extraction done in ${elapsed}s  [success=${result.success}]`);
    console.log('='.repeat(60));
    console.log('\n📋 RAW RESULT:');
    console.log(JSON.stringify(result, null, 2));
    console.log('\n' + '='.repeat(60));
    console.log('📊 Summary:');
    console.log(`   Doctor:   ${result.doctorName}`);
    console.log(`   Diagnosis: ${result.diagnosis}`);
    console.log(`   Medicines Found: ${result.medicines.length}`);
    result.medicines.forEach((med, i) => {
        console.log(`\n   Medicine #${i + 1}:`);
        console.log(`     Name:     ${med.name}`);
        console.log(`     Dosage:   ${med.dosage}`);
        console.log(`     Timing:   ${med.timing}`);
        console.log(`     Context:  ${med.context}`);
        console.log(`     Duration: ${med.durationDays} days`);
        if (med.instruction) console.log(`     Note:     ${med.instruction}`);
    });
    console.log('\n' + '='.repeat(60));
}

runTest().catch(err => {
    console.error('\n❌ Test failed:', err.message);
    process.exit(1);
});
