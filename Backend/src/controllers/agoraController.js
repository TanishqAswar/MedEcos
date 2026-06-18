const { RtcTokenBuilder, RtcRole } = require('agora-token');

exports.generateToken = (req, res) => {
    try {
        const { channelName, uid } = req.query;

        if (!channelName) {
            return res.status(400).json({ error: 'channelName is required' });
        }

        const appId = process.env.AGORA_APP_ID;
        const appCertificate = process.env.AGORA_APP_CERTIFICATE;

        if (!appId || !appCertificate) {
            return res.status(500).json({ error: 'Agora keys not configured on server' });
        }

        // Get uid
        let uidInt = 0;
        if (uid) {
            uidInt = parseInt(uid, 10);
        }

        // Role
        // role 1 = Publisher, 2 = Subscriber. We'll use Publisher for both doctor and patient
        const role = RtcRole.PUBLISHER;

        // Set privilege expire time (e.g. 1 hour)
        const expirationTimeInSeconds = 3600;
        const currentTimestamp = Math.floor(Date.now() / 1000);
        const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

        // Build token
        const token = RtcTokenBuilder.buildTokenWithUid(
            appId,
            appCertificate,
            channelName,
            uidInt,
            role,
            expirationTimeInSeconds,
            privilegeExpiredTs
        );

        return res.json({ token, channelName, uid: uidInt });
    } catch (error) {
        console.error('Error generating Agora token:', error);
        res.status(500).json({ error: 'Failed to generate token' });
    }
};
