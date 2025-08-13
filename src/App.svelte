<script>
  import md from '../ffmq.md?raw';

  // FFMQ-39 Scoring Rules:
  // - Items are scored 1-5 (1=Never/rarely true, 5=Very often/always true)
  // - Reverse-scored items (1→5, 2→4, 3→3, 4→2, 5→1): 3, 5, 8, 10, 12, 13, 14, 16, 17, 18, 22, 23, 25, 28, 30, 34, 35, 38, 39
  // - Subscales: Observing, Describing, Acting with Awareness, Nonjudging, Nonreactivity
  // - Total score = sum of all 39 items (after reverse scoring where applicable)
  // - Minimum possible score: 39, Maximum possible score: 195
  
  const REVERSE_ITEMS = new Set([3, 5, 8, 10, 12, 13, 14, 16, 17, 18, 22, 23, 25, 28, 30, 34, 35, 38, 39]);
  const FACETS = {
    Observing: [1, 6, 11, 15, 20, 26, 31, 36],
    Describing: [2, 7, 12, 16, 22, 27, 32, 37],
    'Acting with Awareness': [5, 8, 13, 18, 23, 28, 34, 38],
    'Nonjudging of Inner Experience': [3, 10, 14, 17, 25, 30, 35, 39],
    'Nonreactivity to Inner Experience': [4, 9, 19, 21, 24, 29, 33]
  };

  // Webhook configuration for N8N
  const WEBHOOK_URL = 'http://192.168.12.200:5678/webhook/mindfulness';

  // Debug mode - set to true for testing with random answers
  const DEBUG_MODE = false;

  // Generate random test answers for debugging
  function generateTestAnswers() {
    const testAnswers = new Map();
    for (let i = 1; i <= 39; i++) {
      testAnswers.set(i, Math.floor(Math.random() * 5) + 1); // Random 1-5
    }
    return testAnswers;
  }

  // Refresh test answers for new random data
  function refreshTestAnswers() {
    if (DEBUG_MODE) {
      answers = generateTestAnswers();
      answers = answers; // trigger reactivity
    }
  }

  // Helper function to convert Map to plain object
  function toObj(map) {
    return Object.fromEntries([...map.entries()].map(([k, v]) => [String(k), v]));
  }

  // Send data to N8N webhook
  async function sendToWebhook(payload) {
    try {
      webhookStatus = null; // Reset status
      const response = await fetch(WEBHOOK_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      
      if (response.ok) {
        webhookStatus = 'success';
      } else {
        webhookStatus = 'error';
      }
    } catch (err) {
      console.error('Webhook send failed:', err);
      webhookStatus = 'error';
    }
  }

  // Send results to webhook (separate from scoring)
  async function sendResultsToWebhook() {
    if (!results) return;
    
    // Recalculate adjusted answers from current answers
    const adjusted = new Map();
    for (const [num, v] of answers.entries()) {
      const adj = REVERSE_ITEMS.has(num) ? reverseScore(v) : v;
      adjusted.set(num, adj);
    }
    
    const payload = {
      session_id: (globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(36).slice(2)}`),
      timestamp: new Date().toISOString(),
      answers_raw: toObj(answers),
      answers_adjusted: toObj(adjusted),
      facet_scores: results.facetScores,
      total_score: results.total
    };

    await sendToWebhook(payload);
  }

  // Descriptions are now stored in ffmq.md alongside each question

  function parseQuestionsFromMarkdown(markdownText) {
    const lines = markdownText.split(/\r?\n/);
    const rows = [];
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith('|')) continue;
      const cells = trimmed.split('|').map((c) => c.trim());
      if (cells.length < 4) continue;
      const maybeNumber = Number(cells[1]);
      if (!Number.isInteger(maybeNumber)) continue;
      const num = maybeNumber;
      const statement = cells[2];
      const description = cells[3] ?? '';
      if (!statement) continue;
      rows.push({ num, statement, description });
    }
    return rows.sort((a, b) => a.num - b.num);
  }

  const questions = parseQuestionsFromMarkdown(md);
  let results = null;
  let answers = new Map();
  let webhookStatus = null; // 'success', 'error', or null
  
  // Initialize with test answers if debug mode is enabled
  if (DEBUG_MODE) {
    answers = generateTestAnswers();
  }
  
  function selectOption(questionNum, value) {
    answers.set(questionNum, value);
    answers = answers; // trigger reactivity
  }

  function reverseScore(value) {
    // For reverse-scored items: 1→5, 2→4, 3→3, 4→2, 5→1
    // This ensures that higher mindfulness responses get higher scores
    switch (value) {
      case 1: return 5;
      case 2: return 4;
      case 3: return 3;
      case 4: return 2;
      case 5: return 1;
      default: return value;
    }
  }

  async function handleSubmit(event) {
    const form = event.currentTarget;
    const fd = new FormData(form);
    const answers = new Map();
    for (const q of questions) {
      const raw = fd.get(`q${q.num}`);
      if (!raw) {
        alert(`Please answer question #${q.num}`);
        return;
      }
      answers.set(q.num, Number(raw));
    }

    // Apply reverse scoring to specified items before calculating totals
    const adjusted = new Map();
    let total = 0;
    for (const [num, v] of answers.entries()) {
      const adj = REVERSE_ITEMS.has(num) ? reverseScore(v) : v;
      adjusted.set(num, adj);
      total += adj;
    }

    // Calculate subscale scores using the adjusted (reverse-scored) values
    const facetScores = {};
    for (const [facet, items] of Object.entries(FACETS)) {
      facetScores[facet] = items.reduce((sum, itemNum) => sum + (adjusted.get(itemNum) ?? 0), 0);
    }

    results = { total, facetScores };
    
    setTimeout(() => window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' }), 0);
  }
</script>

<main class="container">
  <header class="page-header">
    <h1>Five Facet Mindfulness Questionnaire (FFMQ-39)</h1>
    <p class="subtitle">Rate each statement from 1 (Never/rarely true) to 5 (Very often/always true).</p>
    {#if DEBUG_MODE}
      <div class="debug-notice">
        🧪 DEBUG MODE: Test answers are pre-filled. Submit to test webhook.
        <button class="refresh-btn" on:click={refreshTestAnswers}>Refresh Answers</button>
      </div>
    {/if}
  </header>

  <form class="card" on:submit|preventDefault={handleSubmit}>

    <div class="questions">
      {#each questions as { num, statement, description }}
        <fieldset class="question" aria-labelledby={`q${num}-label`}>
          <div class="q-head">
            <div class="q-num">Question {num}</div>
            <p class="q-text" id={`q${num}-label`}>{statement}</p>
            <p class="q-desc">{description}</p>
          </div>
          <div class="q-options">
            {#each [1,2,3,4,5] as v}
              {@const scaleLabels = ['Never or very rarely true', 'Rarely true', 'Sometimes true', 'Often true', 'Very often or always true']}
              {@const isSelected = answers.get(num) === v}
              <label class="option {isSelected ? 'selected' : ''}">
                <input 
                  type="radio" 
                  name={`q${num}`} 
                  value={v} 
                  required 
                  checked={answers.get(num) === v}
                  on:change={() => selectOption(num, v)}
                />
                <span class="scale-value">{v}</span>
                <span class="scale-label">{scaleLabels[v-1]}</span>
              </label>
            {/each}
          </div>
        </fieldset>
      {/each}
    </div>

    <div class="form-actions">
      <button class="btn" type="submit">📊 Score Questionnaire</button>
      <p class="form-note">This will calculate your scores. Use the "Save Results" button below to store them in the database.</p>
    </div>
  </form>

  {#if results}
    <section class="results">
      <div class="card">
        <h3>Results</h3>
        <p><strong>Total Score:</strong> {results.total} <span class="score-range">(Range: 39-195)</span></p>
        <p>Higher score = more developed mindfulness skills.</p>
        <p class="score-interpretation">
          <strong>Score Interpretation:</strong><br>
          39-77: Low mindfulness<br>
          78-116: Moderate mindfulness<br>
          117-195: High mindfulness
        </p>
        <div class="facet-scores">
          {#each Object.entries(results.facetScores) as [facet, score]}
            <div class="facet">
              <h4>{facet}</h4>
              <p><strong>Score:</strong> {score}</p>
            </div>
          {/each}
        </div>
        
        <!-- Webhook Section -->
        <div class="webhook-section">
          <h4>Save Results</h4>
          <p>Click the button below to save your results to the database:</p>
          <button class="btn webhook-btn" on:click={sendResultsToWebhook} disabled={webhookStatus === 'success'}>
            {webhookStatus === 'success' ? '✅ Results Saved!' : '💾 Save Results to Database'}
          </button>
          
          {#if webhookStatus === 'success'}
            <div class="webhook-success">
              <p>✅ Your results have been successfully saved!</p>
            </div>
          {:else if webhookStatus === 'error'}
            <div class="webhook-error">
              <p>❌ Failed to save results. Please try again.</p>
            </div>
          {/if}
        </div>
      </div>
    </section>
  {/if}

  <footer class="page-footer">
  </footer>
</main>


