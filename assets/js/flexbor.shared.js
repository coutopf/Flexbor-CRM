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

  window.FlexborShared = Object.freeze({
    createLookup,
    createSupabaseClient,
    clearStoredSession,
    setGlobalLoading
  });
})();
