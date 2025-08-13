<script>
  import ffmqMd from '../ffmq.md?raw';
  import mwqMd from '../mwq.md?raw';

  // FFMQ-39 constants (unchanged)
  const FFMQ_REVERSE_ITEMS = new Set([3, 5, 8, 10, 12, 13, 14, 16, 17, 18, 22, 23, 25, 28, 30, 34, 35, 38, 39]);
  const FFMQ_FACETS = {
    Observing: [1, 6, 11, 15, 20, 26, 31, 36],
    Describing: [2, 7, 12, 16, 22, 27, 32, 37],
    'Acting with Awareness': [5, 8, 13, 18, 23, 28, 34, 38],
    'Nonjudging of Inner Experience': [3, 10, 14, 17, 25, 30, 35, 39],
    'Nonreactivity to Inner Experience': [4, 9, 19, 21, 24, 29, 33]
  };

  // Webhook configuration for N8N
  const WEBHOOK_URL = 'http://192.168.12.200:5678/webhook-test/mindfulness';

  // Debug mode - set to true for testing with random answers
  const DEBUG_MODE = true;

  // Questionnaires registry
  const QUESTIONNAIRES = {
    ffmq: {
      id: 'ffmq',
      title: 'Five Facet Mindfulness Questionnaire (FFMQ-39)',
      subtitle: 'Rate each statement from 1 (Never/rarely true) to 5 (Very often/always true).',
      markdown: ffmqMd,
      scaleValues: [1, 2, 3, 4, 5],
      scaleLabels: ['Never or very rarely true', 'Rarely true', 'Sometimes true', 'Often true', 'Very often or always true'],
      scoring: 'ffmq'
    },
    mwq: {
      id: 'mwq',
      title: 'Mind-Wandering Questionnaire (MWQ)',
      subtitle: 'Rate each statement from 1 (Almost never) to 6 (Almost always).',
      markdown: mwqMd,
      scaleValues: [1, 2, 3, 4, 5, 6],
      scaleLabels: ['Almost never', 'Very infrequently', 'Somewhat infrequently', 'Somewhat frequently', 'Very frequently', 'Almost always'],
      scoring: 'average'
    }
  };

  // Generate random test answers for debugging for the selected questionnaire
  function generateTestAnswers(numQuestions, minValue, maxValue) {
    const testAnswers = new Map();
    for (let i = 1; i <= numQuestions; i++) {
      testAnswers.set(i, Math.floor(Math.random() * (maxValue - minValue + 1)) + minValue);
    }
    return testAnswers;
  }

  function refreshTestAnswers() {
    if (DEBUG_MODE) {
      answers = generateTestAnswers(questions.length, current.scaleValues[0], current.scaleValues[current.scaleValues.length - 1]);
      answers = answers; // trigger reactivity
    }
  }

  function toObj(map) {
    return Object.fromEntries([...map.entries()].map(([k, v]) => [String(k), v]));
  }

  async function sendToWebhook(payload) {
    try {
      webhookStatus = null;
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

  // Parse questions from markdown table
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

  let selectedQuestionnaireId = 'ffmq';
  let current = QUESTIONNAIRES[selectedQuestionnaireId];
  let questions = parseQuestionsFromMarkdown(current.markdown);
  let results = null;
  let answers = new Map();
  let webhookStatus = null; // 'success', 'error', or null

  if (DEBUG_MODE) {
    answers = generateTestAnswers(questions.length, current.scaleValues[0], current.scaleValues[current.scaleValues.length - 1]);
  }

  function onQuestionnaireChange(event) {
    selectedQuestionnaireId = event.target.value;
    current = QUESTIONNAIRES[selectedQuestionnaireId];
    questions = parseQuestionsFromMarkdown(current.markdown);
    results = null;
    answers = DEBUG_MODE ? generateTestAnswers(questions.length, current.scaleValues[0], current.scaleValues[current.scaleValues.length - 1]) : new Map();
  }

  function selectOption(questionNum, value) {
    answers.set(questionNum, value);
    answers = answers; // trigger reactivity
  }

  function ffmqReverseScore(value) {
    switch (value) {
      case 1: return 5;
      case 2: return 4;
      case 3: return 3;
      case 4: return 2;
      case 5: return 1;
      default: return value;
    }
  }

  async function sendResultsToWebhook() {
    if (!results) return;

    const adjusted = new Map();
    if (selectedQuestionnaireId === 'ffmq') {
      for (const [num, v] of answers.entries()) {
        const adj = FFMQ_REVERSE_ITEMS.has(num) ? ffmqReverseScore(v) : v;
        adjusted.set(num, adj);
      }
      const payload = {
        session_id: (globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(36).slice(2)}`),
        timestamp: new Date().toISOString(),
        questionnaire_id: 'ffmq',
        answers_raw: toObj(answers),
        answers_adjusted: toObj(adjusted),
        facet_scores: results.facetScores,
        total_score: results.total
      };
      await sendToWebhook(payload);
    } else if (selectedQuestionnaireId === 'mwq') {
      // No reverse scoring for MWQ
      for (const [num, v] of answers.entries()) {
        adjusted.set(num, v);
      }
      const payload = {
        session_id: (globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(36).slice(2)}`),
        timestamp: new Date().toISOString(),
        questionnaire_id: 'mwq',
        answers_raw: toObj(answers),
        answers_adjusted: toObj(adjusted),
        average_score: results.average,
        total_score: results.total // optional aggregate
      };
      await sendToWebhook(payload);
    }
  }

  async function handleSubmit(event) {
    const form = event.currentTarget;
    const fd = new FormData(form);
    const localAnswers = new Map();
    for (const q of questions) {
      const raw = fd.get(`q${q.num}`);
      if (!raw) {
        alert(`Please answer question #${q.num}`);
        return;
      }
      localAnswers.set(q.num, Number(raw));
    }

    if (selectedQuestionnaireId === 'ffmq') {
      const adjusted = new Map();
      let total = 0;
      for (const [num, v] of localAnswers.entries()) {
        const adj = FFMQ_REVERSE_ITEMS.has(num) ? ffmqReverseScore(v) : v;
        adjusted.set(num, adj);
        total += adj;
      }
      const facetScores = {};
      for (const [facet, items] of Object.entries(FFMQ_FACETS)) {
        facetScores[facet] = items.reduce((sum, itemNum) => sum + (adjusted.get(itemNum) ?? 0), 0);
      }
      answers = localAnswers;
      results = { total, facetScores };
    } else if (selectedQuestionnaireId === 'mwq') {
      let total = 0;
      for (const v of localAnswers.values()) total += v;
      const average = total / questions.length;
      answers = localAnswers;
      results = { total, average };
    }

    setTimeout(() => window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' }), 0);
  }
</script>

<main class="container">
  <header class="page-header">
    <div class="qnr-select">
      <label for="qnr">Questionnaire:</label>
      <select id="qnr" on:change={onQuestionnaireChange}>
        <option value="ffmq" selected={selectedQuestionnaireId === 'ffmq'}>FFMQ-39</option>
        <option value="mwq" selected={selectedQuestionnaireId === 'mwq'}>MWQ</option>
      </select>
    </div>
    <h1>{current.title}</h1>
    <p class="subtitle">{current.subtitle}</p>
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
            {#each current.scaleValues as v}
              {@const scaleLabels = current.scaleLabels}
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
        {#if selectedQuestionnaireId === 'ffmq'}
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
        {:else if selectedQuestionnaireId === 'mwq'}
          <p><strong>Average Score:</strong> {results.average.toFixed(2)} <span class="score-range">(Range: 1-6)</span></p>
          <p>1 = Very little mind-wandering (or "Almost Never")<br>6 = A lot of mind-wandering (or "Almost Always")</p>
        {/if}

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


