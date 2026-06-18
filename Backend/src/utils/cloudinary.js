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
const uploadToCloudinary = (fileBuffer, originalName = null) => {
    return new Promise((resolve, reject) => {
        const options = {
            resource_type: "auto", // Allows PDF previews
            folder: "medecos_reports"
        };

        if (originalName) {
            options.use_filename = true;
            options.filename_override = originalName;
            options.unique_filename = true;
        }

        const cld_upload_stream = cloudinary.uploader.upload_stream(
            options,
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
