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

  const DESCRIPTIONS = {
    1: "Invites you to notice concrete bodily sensations (pressure, contact, temperature, muscle activation) while walking. Think heels and toes, joint angles, balance shifts, air on skin—staying with raw sensation rather than commentary.",
    2: "Assesses emotional vocabulary and precision. Can you move beyond broad labels (good/bad) to nuanced terms (disappointed vs. sad vs. resigned) and articulate intensity, triggers, and context?",
    3: "Probes secondary judgment about emotions—seeing them as irrational/inappropriate and criticizing yourself for having them. The intention is to detect a punitive stance toward inner experience.",
    4: "Targets nonreactivity: perceiving feelings as transient events without needing to fix, suppress, or amplify them. Can you allow an urge or emotion to be present without immediately acting?",
    5: "Measures acting-with-awareness versus autopilot. Mind wandering during tasks suggests reduced moment-to-moment contact with what you’re doing (sensations, intentions, and actions).",
    6: "Checks sensory contact in everyday routines. Can you feel temperature, pressure, flow, and texture of water on the skin without drifting into thought?",
    7: "Looks at the ability to translate inner beliefs/opinions into clear language—organizing experience into shareable, coherent statements.",
    8: "Captures inattention caused by mental time-travel (worry, rumination, fantasy). The focus is on noticing when attention leaves the task and the body.",
    9: "Assesses the capacity to witness feelings without fusing with them. You can notice sadness/anger as an experience occurring in awareness, not as your entire identity.",
    10: "Surfaces judgment of emotion itself (meta-judgment). The intention is to see whether you label certain feelings as unacceptable and pressure yourself not to feel them.",
    11: "Examines interoceptive and affective consequences of consumption. Do you notice shifts in energy, mood, clarity, tension, or heart rate after foods/drinks?",
    12: "Measures difficulty putting thoughts into words—accessing and naming the content/quality of thinking (speed, imagery, verbal tone, certainty).",
    13: "Screens distractibility—how easily attention is pulled from the intended object (task, breath, conversation) by internal or external stimuli.",
    14: "Explores judgment about thoughts as morally/qualitatively bad. Do you relate to certain thoughts as unacceptable rather than as passing mental events?",
    15: "Checks openness to subtle sensory input (wind, warmth, texture). It reflects a curious, receptive stance toward raw perception in daily life.",
    16: "Assesses difficulty describing feelings under ordinary conditions—whether there’s a gap between felt experience and language generation.",
    17: "Targets the reflex to evaluate thoughts as good/bad. The item taps the judging dimension rather than the content of specific thoughts.",
    18: "Captures stability of attention in the present. Difficulty staying focused signals reduced awareness continuity and greater autopilot.",
    19: "Measures decentering: the ability to ‘step back’ from distressing images/thoughts, seeing them as mental events that arise and pass without takeover.",
    20: "Checks auditory mindfulness—discriminating layers of sound (near/far, loud/soft, continuous/intermittent) without narrating or evaluating.",
    21: "Assesses response inhibition and emotional regulation: pausing in difficulty to allow wiser action rather than reflexive reaction.",
    22: "Explores interoceptive language—can you identify and name bodily sensations (tightness, flutter, pressure, heat) with some specificity?",
    23: "Screens behavioral autopilot—doing without noticing intentions, transitions, or sensations. Reflects low present-moment contact during routine behavior.",
    24: "Targets recovery and nonreactivity after distressing mentation—how quickly equanimity returns once a difficult thought/image appears.",
    25: "Assesses judgment about thinking itself—pressuring yourself not to have certain thoughts, which often amplifies distress and reduces acceptance.",
    26: "Checks olfactory awareness—subtle noticing of aromas in ordinary contexts (food, outdoors, environments) without evaluation.",
    27: "Measures access to language for emotion under load. Even when upset, can you label and communicate what you feel and need?",
    28: "Captures speed-over-awareness tendency: rushing diminishes sensory contact and intentionality; mindfulness favors thorough, deliberate engagement.",
    29: "Assesses the ability to allow distressing thoughts/images to be present while choosing nonreactive, values-guided behavior.",
    30: "Surfaces moral/aesthetic judgment of emotions (good/bad). Mindfulness emphasizes accepting emotions as signals, not faults.",
    31: "Checks visual mindfulness—rich noticing of color, line, texture, light/shadow in art/nature, indicating receptive perceptual detail.",
    32: "Assesses narrative tendency—readiness to represent experience in words, building coherent meaning without losing contact with raw data.",
    33: "Measures letting-go ability—recognizing thoughts/images and allowing them to pass without elaboration or struggle.",
    34: "Screens automaticity in action—tasks completed with minimal awareness of steps, sensations, and intentions.",
    35: "Explores self-evaluation tied to thought content. Do you judge yourself as good/bad because of having certain thoughts/images?",
    36: "Assesses insight into how emotions bias cognition and behavior—tracking shifts in attention, memory, choices when emotions arise.",
    37: "Checks emotional granularity and detail in the present moment—naming blends, intensities, and bodily correlates of feeling states.",
    38: "Captures acting without awareness—only later realizing you’ve been on autopilot. Overlaps with attentional stability in daily tasks.",
    39: "Targets disapproval toward having ‘irrational’ ideas—self-criticism for mental content rather than noticing it as transient activity."
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

    <div class="questions">
      {#each questions as { num, statement }}
        <fieldset class="question" aria-labelledby={`q${num}-label`}>
          <div class="q-head">
            <div class="q-num">Question {num}</div>
            <p class="q-text" id={`q${num}-label`}>{statement}</p>
            <p class="q-desc">{DESCRIPTIONS[num]}</p>
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


