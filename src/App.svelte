<script>
  import md from '../ffmq.md?raw';

  const REVERSE_ITEMS = new Set([3, 10, 12, 14, 16, 17, 18, 23, 25, 28, 30, 34, 35, 38, 39]);
  const FACETS = {
    Observing: [1, 6, 11, 15, 20, 26, 31, 36],
    Describing: [2, 7, 12, 16, 22, 27, 32, 37],
    'Acting with Awareness': [5, 8, 13, 18, 23, 28, 34, 38],
    'Nonjudging of Inner Experience': [3, 10, 14, 17, 25, 30, 35, 39],
    'Nonreactivity to Inner Experience': [4, 9, 19, 21, 24, 29, 33]
  };

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
      if (!statement) continue;
      rows.push({ num, statement });
    }
    return rows.sort((a, b) => a.num - b.num);
  }

  const questions = parseQuestionsFromMarkdown(md);
  let results = null;
  let answers = new Map();
  
  function selectOption(questionNum, value) {
    answers.set(questionNum, value);
    answers = answers; // trigger reactivity
  }

  function reverseScore(value) {
    switch (value) {
      case 1: return 5;
      case 2: return 4;
      case 3: return 3;
      case 4: return 2;
      case 5: return 1;
      default: return value;
    }
  }

  function handleSubmit(event) {
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

    const adjusted = new Map();
    let total = 0;
    for (const [num, v] of answers.entries()) {
      const adj = REVERSE_ITEMS.has(num) ? reverseScore(v) : v;
      adjusted.set(num, adj);
      total += adj;
    }

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
  </header>

  <form class="card" on:submit|preventDefault={handleSubmit}>
    <div class="legend">
      <h3>Instructions</h3>
      <p>Please rate each statement according to how frequently or how true it is of you. Use the following scale:</p>
      <div class="scale-legend">
        <div class="scale-item">
          <span class="scale-value">1</span>
          <span class="scale-label">Never or very rarely true</span>
        </div>
        <div class="scale-item">
          <span class="scale-value">2</span>
          <span class="scale-label">Rarely true</span>
        </div>
        <div class="scale-item">
          <span class="scale-value">3</span>
          <span class="scale-label">Sometimes true</span>
        </div>
        <div class="scale-item">
          <span class="scale-value">4</span>
          <span class="scale-label">Often true</span>
        </div>
        <div class="scale-item">
          <span class="scale-value">5</span>
          <span class="scale-label">Very often or always true</span>
        </div>
      </div>
    </div>

    <div class="questions">
      {#each questions as { num, statement }}
        <fieldset class="question" aria-labelledby={`q${num}-label`}>
          <div class="q-head">
            <div class="q-num">Question {num}</div>
            <p class="q-text" id={`q${num}-label`}>{statement}</p>
          </div>
          <div class="q-options">
            {#each [1,2,3,4,5] as v}
              {@const scaleLabels = ['Never or very rarely true', 'Rarely true', 'Sometimes true', 'Often true', 'Very often or always true']}
              {@const isSelected = answers.get(num) === v}
              <label class="option {isSelected ? 'selected' : ''}" on:click={() => selectOption(num, v)}>
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
      <button class="btn" type="submit">Submit and Score</button>
    </div>
  </form>

  {#if results}
    <section class="results">
      <div class="card">
        <h3>Results</h3>
        <p><strong>Total Score:</strong> {results.total}</p>
        <p>Higher score = more developed mindfulness skills.</p>
        <div class="facet-scores">
          {#each Object.entries(results.facetScores) as [facet, score]}
            <div class="facet">
              <h4>{facet}</h4>
              <p><strong>Score:</strong> {score}</p>
            </div>
          {/each}
        </div>
      </div>
    </section>
  {/if}

  <footer class="page-footer">
    <p>
      Scoring: Items <strong>3, 10, 12, 14, 16, 17, 18, 23, 25, 28, 30, 34, 35, 38, 39</strong> are reverse-scored.
      Facets: Observing; Describing; Acting with Awareness; Nonjudging of Inner Experience; Nonreactivity to Inner Experience.
    </p>
  </footer>
</main>


