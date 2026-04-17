(function () {
  function requireConfig() {
    const cfg = window.FLEXBOR_CONFIG?.supabase;
    if (!cfg?.url || !cfg?.anonKey) {
      throw new Error('Supabase config missing. Check supabase.config.js');
    }
    return cfg;
  }

  function createSupabaseClient(storageKey, authOverrides) {
    const cfg = requireConfig();
    return supabase.createClient(cfg.url, cfg.anonKey, {
      auth: {
        storageKey,
        ...authOverrides
      }
    });
  }

  function clearStoredSession() {
    Object.keys(localStorage).forEach((key) => {
      if (key.startsWith('sb-') || key.startsWith('supabase') || key.startsWith('flexbor-')) {
        localStorage.removeItem(key);
      }
    });

    Object.keys(sessionStorage).forEach((key) => {
      if (key.startsWith('sb-') || key.startsWith('supabase')) {
        sessionStorage.removeItem(key);
      }
    });
  }

  function createLookup(items) {
    return Object.fromEntries((items || []).map((item) => [item.id, item]));
  }

  function setGlobalLoading(isLoading) {
    document.body?.classList.toggle('is-loading', !!isLoading);
  }

  function getDefaultCrmConfig() {
    return {
      pipeline_fases: ['Prospeccao', 'Qualificacao', 'Proposta', 'Negociacao', 'Fechado - Ganho', 'Fechado - Perdido'],
      tags_oportunidade: [],
      motivos_ganho: [],
      motivos_perda: [],
      campos_customizados: [],
      regras: {
        followup_visita_dias: 2,
        oportunidade_sem_atividade_dias: 30,
        cliente_sem_contacto_dias: 45,
        fecho_alerta_7_dias: 7,
        fecho_alerta_30_dias: 30,
        tarefa_critica_dias: 0,
        followup_visita_automatica: true
      }
    };
  }

  function normalizeStringList(value) {
    if (!Array.isArray(value)) return [];
    return value
      .map((item) => String(item || '').trim())
      .filter(Boolean);
  }

  function normalizeRules(value) {
    const defaults = getDefaultCrmConfig().regras;
    const raw = value && typeof value === 'object' ? value : {};
    return {
      followup_visita_dias: Math.max(parseInt(raw.followup_visita_dias, 10) || defaults.followup_visita_dias, 0),
      oportunidade_sem_atividade_dias: Math.max(parseInt(raw.oportunidade_sem_atividade_dias, 10) || defaults.oportunidade_sem_atividade_dias, 1),
      cliente_sem_contacto_dias: Math.max(parseInt(raw.cliente_sem_contacto_dias, 10) || defaults.cliente_sem_contacto_dias, 1),
      fecho_alerta_7_dias: Math.max(parseInt(raw.fecho_alerta_7_dias, 10) || defaults.fecho_alerta_7_dias, 1),
      fecho_alerta_30_dias: Math.max(parseInt(raw.fecho_alerta_30_dias, 10) || defaults.fecho_alerta_30_dias, 1),
      tarefa_critica_dias: Math.max(parseInt(raw.tarefa_critica_dias, 10) || defaults.tarefa_critica_dias, 0),
      followup_visita_automatica: raw.followup_visita_automatica !== false
    };
  }

  function normalizeCrmConfig(row) {
    const defaults = getDefaultCrmConfig();
    const source = row && typeof row === 'object' ? row : {};
    return {
      ...defaults,
      ...source,
      pipeline_fases: normalizeStringList(source.pipeline_fases).length ? normalizeStringList(source.pipeline_fases) : defaults.pipeline_fases,
      tags_oportunidade: normalizeStringList(source.tags_oportunidade),
      motivos_ganho: normalizeStringList(source.motivos_ganho),
      motivos_perda: normalizeStringList(source.motivos_perda),
      campos_customizados: normalizeStringList(source.campos_customizados),
      regras: normalizeRules(source.regras)
    };
  }

  function deriveOpportunityState(fase) {
    const value = String(fase || '').toLowerCase();
    if (value.includes('ganh')) return 'ganha';
    if (value.includes('perd')) return 'perdida';
    return 'aberta';
  }

  window.FlexborShared = Object.freeze({
    createLookup,
    createSupabaseClient,
    clearStoredSession,
    setGlobalLoading,
    getDefaultCrmConfig,
    normalizeCrmConfig,
    deriveOpportunityState
  });
})();
