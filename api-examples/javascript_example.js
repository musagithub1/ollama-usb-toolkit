/**
 * Ollama API Examples - JavaScript (Node.js / Browser fetch)
 * Works in Node.js 18+ (native fetch) or any modern browser.
 */

const OLLAMA_URL = "http://localhost:11434";
const MODEL = "tinyllama";

// --- List Models ---
async function listModels() {
    console.log("\n--- List Models ---");
    try {
        const res = await fetch(`${OLLAMA_URL}/api/tags`);
        const data = await res.json();
        data.models.forEach(m => {
            const sizeGB = (m.size / 1e9).toFixed(1);
            console.log(`  ${m.name.padEnd(30)} ${sizeGB} GB`);
        });
    } catch (e) {
        console.log(`  Error: ${e.message}`);
    }
}

// --- Generate Text ---
async function generate(prompt) {
    console.log(`\n--- Generate ---`);
    console.log(`  Prompt: ${prompt}`);
    try {
        const res = await fetch(`${OLLAMA_URL}/api/generate`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ model: MODEL, prompt, stream: false })
        });
        const data = await res.json();
        console.log(`  Response: ${data.response}`);
    } catch (e) {
        console.log(`  Error: ${e.message}`);
    }
}

// --- Chat ---
async function chat(messages) {
    console.log(`\n--- Chat ---`);
    try {
        const res = await fetch(`${OLLAMA_URL}/api/chat`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ model: MODEL, messages, stream: false })
        });
        const data = await res.json();
        console.log(`  Assistant: ${data.message.content}`);
    } catch (e) {
        console.log(`  Error: ${e.message}`);
    }
}

// --- Streaming Generate ---
async function streamGenerate(prompt) {
    console.log(`\n--- Streaming ---`);
    console.log(`  Prompt: ${prompt}`);
    process.stdout.write("  Response: ");
    try {
        const res = await fetch(`${OLLAMA_URL}/api/generate`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ model: MODEL, prompt, stream: true })
        });
        const reader = res.body.getReader();
        const decoder = new TextDecoder();
        while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            const lines = decoder.decode(value).split("\n").filter(l => l);
            for (const line of lines) {
                try {
                    const json = JSON.parse(line);
                    process.stdout.write(json.response || "");
                } catch {}
            }
        }
        console.log();
    } catch (e) {
        console.log(`\n  Error: ${e.message}`);
    }
}

// --- Run Examples ---
(async () => {
    console.log("==================================================");
    console.log("  Ollama API - JavaScript Examples");
    console.log("==================================================");

    await listModels();
    await generate("What is JavaScript in one sentence?");
    await chat([
        { role: "system", content: "You are a helpful assistant." },
        { role: "user", content: "What is an API?" }
    ]);
    await streamGenerate("Write a haiku about programming.");

    console.log("\nDone!");
})();
