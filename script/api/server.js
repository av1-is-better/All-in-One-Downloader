const express = require('express');
const cors = require('cors');
const fs = require('fs');
const axios = require('axios');

const app = express();

// Enable CORS for all routes
app.use(cors());
app.use(express.json());

// Read the auth token from file
let AUTH_TOKEN = '';
try {
    AUTH_TOKEN = fs.readFileSync('/app/config/.rpc_secret', 'utf-8').trim();
    if (!AUTH_TOKEN) throw new Error('Token file is empty');
} catch (err) {
    console.error('Failed to read auth token:', err.message);
    process.exit(1);
}

// Middleware for authorization
function authMiddleware(req, res, next) {
    const authHeader = req.headers['authorization'];
    const expected = `Bearer ${AUTH_TOKEN}`;
    if (!authHeader || authHeader !== expected) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
}

// Extract UUID from Google Drive HTML page
function extractUUID(html_code) {
    const uuidRegex = /<input[^>]+name=["']uuid["'][^>]+value=["']([a-f0-9-]{36})["']/i;
    const match = html_code.match(uuidRegex);
    return match ? match[1] : null;
}

// Extract Google Drive file ID from various URL formats
function extractDriveFileId(url) {
    const patterns = [
        /\/d\/([a-zA-Z0-9_-]{10,})/,                       // /file/d/ID/
        /id=([a-zA-Z0-9_-]{10,})/,                          // ?id=ID
        /\/uc\?export=download&id=([a-zA-Z0-9_-]{10,})/,   // /uc?export=download&id=ID
        /\/folders\/([a-zA-Z0-9_-]{10,})/,                // /folders/ID
        /\?[^#]*id=([a-zA-Z0-9_-]{10,})/                   // any ?...id=ID
    ];
    for (const pattern of patterns) {
        const match = url.match(pattern);
        if (match) return match[1];
    }
    return null;
}

// POST /addtask
app.post('/addtask', authMiddleware, async (req, res) => {
    const { type, url } = req.body;
    if (!type || !url) {
        return res.status(400).json({ error: 'Missing type or url in request body' });
    }

    if (type !== 'google-drive') {
        return res.status(400).json({ error: 'Only google-drive type is supported' });
    }

    const fileId = extractDriveFileId(url);
    if (!fileId) {
        return res.status(400).json({ error: 'Invalid or unrecognized Google Drive URL' });
    }

    try {
        const htmlResponse = await axios.get(`https://drive.google.com/uc?export=download&id=${fileId}`);
        const htmlCode = htmlResponse.data;

        const uuid = extractUUID(htmlCode);
        if (!uuid) {
            return res.status(400).json({ error: 'Unable to extract UUID from Google Drive page' });
        }

        const downloadUrl = `https://drive.usercontent.google.com/download?id=${fileId}&export=download&authuser=0&confirm=t&uuid=${uuid}`;

        const RPC_SERVER_URL = 'http://localhost:61805/jsonrpc';
        const payload = {
            jsonrpc: '2.0',
            method: 'aria2.addUri',
            id: 'add-url',
            params: [
                `token:${AUTH_TOKEN}`,
                [downloadUrl]
            ]
        };

        const rpcResponse = await axios.post(RPC_SERVER_URL, payload);

        if (rpcResponse.data.error) {
            throw new Error(rpcResponse.data.error.message);
        }

        return res.status(200).json({ message: 'Task added to Aria2 successfully' });
    } catch (error) {
        console.error('Error adding task:', error.message);
        return res.status(500).json({ error: 'Failed to add task to Aria2', details: error.message });
    }
});

// Start server on 127.0.0.1:3000
const PORT = 3000;
const HOST = '127.0.0.1';
app.listen(PORT, HOST, () => {
    console.log(`Server running at http://${HOST}:${PORT}`);
});
