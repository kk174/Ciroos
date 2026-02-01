#!/usr/bin/env node
// Simple webhook receiver for Ciroos demo
// Receives Splunk alerts and logs them

const http = require('http');
const port = 3000;

const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/api/alerts') {
    let body = '';

    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      console.log('\n========================================');
      console.log('🚨 ALERT RECEIVED FROM SPLUNK');
      console.log('========================================');
      console.log('Timestamp:', new Date().toISOString());
      console.log('');

      try {
        const alert = JSON.parse(body);
        console.log('Alert Details:');
        console.log(`  Incident ID: ${alert.incidentId || 'N/A'}`);
        console.log(`  Detector: ${alert.detectorName || 'N/A'}`);
        console.log(`  Severity: ${alert.severity || 'N/A'}`);
        console.log(`  Status: ${alert.status || 'N/A'}`);
        console.log(`  Service: ${alert.dimensions?.sf_service || 'N/A'}`);
        console.log('');
        console.log('Full Payload:');
        console.log(JSON.stringify(alert, null, 2));
      } catch (e) {
        console.log('Raw Payload:');
        console.log(body);
      }

      console.log('========================================');
      console.log('✅ CIROOS AI INVESTIGATION TRIGGERED');
      console.log('========================================\n');

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        status: 'received',
        message: 'Alert received by Ciroos',
        timestamp: new Date().toISOString()
      }));
    });
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

server.listen(port, () => {
  console.log(`\n🎯 Ciroos Webhook Receiver Started`);
  console.log(`   Listening on: http://localhost:${port}/api/alerts`);
  console.log(`   Waiting for alerts from Splunk...\n`);
});
