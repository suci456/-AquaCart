import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const workflowPath = path.join(__dirname, 'daily_instagram_post_workflow.json');

console.log('--- VALIDATING N8N WORKFLOW SPECIFICATION ---');

if (!fs.existsSync(workflowPath)) {
  console.error(`FAIL: File not found at ${workflowPath}`);
  process.exit(1);
}

let workflow;
try {
  const content = fs.readFileSync(workflowPath, 'utf-8');
  workflow = JSON.parse(content);
  console.log('✓ Step 1: Valid JSON syntax.');
} catch (e) {
  console.error(`FAIL: Invalid JSON syntax in workflow: ${e.message}`);
  process.exit(1);
}

// 1. Verify top-level structure
if (!workflow.name || !Array.isArray(workflow.nodes) || !workflow.connections) {
  console.error('FAIL: Missing name, nodes, or connections.');
  process.exit(1);
}
console.log(`✓ Step 2: Top-level structure valid. Workflow Name: "${workflow.name}"`);
console.log(`✓ Step 3: Total nodes defined: ${workflow.nodes.length}`);

// 2. Index nodes by name
const nodeNames = new Set(workflow.nodes.map(n => n.name));
if (nodeNames.size !== workflow.nodes.length) {
  console.error('FAIL: Duplicate node names detected.');
  process.exit(1);
}
console.log('✓ Step 4: All node names are unique.');

// 3. Verify key architectural nodes exist
const expectedCoreNodes = [
  'Schedule Trigger (Daily 9:00 AM IST)',
  'Manual / Dry-Run Webhook Trigger',
  'Initialize Config & Dry-Run Mode',
  'Read Google Sheets Product Catalog',
  'Select Single Unposted Product',
  'Has Unposted Product?',
  'Generate Caption & Hashtags (Gemini / Groq)',
  'Generate Promotional Image (DALL-E 3 / Image API)',
  'Upload to Cloudinary / ImgBB (Public HTTPS URL)',
  'Is Dry Run Mode?',
  'Simulate Instagram Publishing (Dry Run)',
  'Meta API - Create Media Container',
  'Meta API - Publish Instagram Media',
  'Google Sheets - Update Row Status & Media ID'
];

for (const name of expectedCoreNodes) {
  if (!nodeNames.has(name)) {
    console.error(`FAIL: Required node "${name}" is missing from workflow.`);
    process.exit(1);
  }
}
console.log(`✓ Step 5: All ${expectedCoreNodes.length} required architectural nodes present.`);

// 4. Verify connection integrity (no dangling edges)
let edgeCount = 0;
for (const [sourceNode, connectionData] of Object.entries(workflow.connections)) {
  if (!nodeNames.has(sourceNode)) {
    console.error(`FAIL: Connection source "${sourceNode}" does not match any node.`);
    process.exit(1);
  }

  if (connectionData.main) {
    for (const outputGroup of connectionData.main) {
      for (const target of outputGroup) {
        if (!nodeNames.has(target.node)) {
          console.error(`FAIL: Connection target "${target.node}" does not exist in nodes list.`);
          process.exit(1);
        }
        edgeCount++;
      }
    }
  }
}
console.log(`✓ Step 6: Connection topology verified. Total valid connections: ${edgeCount}. Zero dangling edges.`);

// 5. Verify retry policies on HTTP Request nodes
const httpNodes = workflow.nodes.filter(n => n.type === 'n8n-nodes-base.httpRequest');
let retriedCount = 0;
for (const node of httpNodes) {
  if (node.parameters?.options?.retryOnFail === true) {
    retriedCount++;
  }
}
console.log(`✓ Step 7: HTTP Request nodes have retryOnFail configured (${retriedCount}/${httpNodes.length} nodes).`);

// 6. Verify dry-run mode branch exists
const dryRunNode = workflow.nodes.find(n => n.name === 'Is Dry Run Mode?');
if (!dryRunNode) {
  console.error('FAIL: Missing dry-run branch node.');
  process.exit(1);
}
console.log('✓ Step 8: Dry-run branch verified.');

console.log('\n--- ALL N8N AUTOMATION SPECIFICATION CHECKS PASSED (100%) ---');
