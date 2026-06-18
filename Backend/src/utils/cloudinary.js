const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');

// Configure Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

/**
 * Uploads a file buffer to Cloudinary and returns the secure URL
 * @param {Buffer} fileBuffer - The file buffer from multer
 * @returns {Promise<string>} The secure URL of the uploaded file
 */
const uploadToCloudinary = (fileBuffer) => {
    return new Promise((resolve, reject) => {
        const cld_upload_stream = cloudinary.uploader.upload_stream(
            {
                resource_type: "raw", // Needed for PDFs
                folder: "medecos_reports"
            },
            (error, result) => {
                if (result) {
                    resolve(result.secure_url);
                } else {
                    reject(error);
                }
            }
        );
        streamifier.createReadStream(fileBuffer).pipe(cld_upload_stream);
    });
};

module.exports = { uploadToCloudinary };
