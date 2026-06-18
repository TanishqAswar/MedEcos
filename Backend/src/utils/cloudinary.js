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
            resource_type: "raw", // Raw is required for proper PDF delivery in browsers
            folder: "medecos_reports"
        };

        if (originalName) {
            options.public_id = originalName;
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

/**
 * Deletes a file from Cloudinary given its secure URL
 * @param {string} fileUrl - The Cloudinary secure URL
 */
const deleteFromCloudinaryByUrl = async (fileUrl) => {
    try {
        if (!fileUrl) return false;
        
        const urlParts = fileUrl.split('/upload/');
        if (urlParts.length < 2) return false;
        
        let pathPart = urlParts[1].split('/').slice(1).join('/'); // remove the v123456 version
        let publicId = pathPart.substring(0, pathPart.lastIndexOf('.')) || pathPart;
        
        // Try deleting as both image (auto for pdfs) and raw (legacy)
        await cloudinary.uploader.destroy(publicId, { resource_type: 'image' });
        await cloudinary.uploader.destroy(pathPart, { resource_type: 'raw' }); 
        
        return true;
    } catch (e) {
        console.error('Error deleting from cloudinary:', e);
        return false;
    }
};

module.exports = { uploadToCloudinary, deleteFromCloudinaryByUrl };
