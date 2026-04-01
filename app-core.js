const SB_URL = "https://oowaowtlwpnypryrlzle.supabase.co";
const SB_KEY = "sb_publishable_P_TyzsiMslz1HCQ3AIAxjw_8ohJOz0N";
const _sb = supabase.createClient(SB_URL, SB_KEY);

const App = {
    toggleModal: (id, show) => document.getElementById(`mov-${id}`).classList.toggle('active', show),
    async getUserData() {
        const { data: { user } } = await _sb.auth.getUser();
        if (!user) return null;
        const { data: prof } = await _sb.from('profiles').select('*').eq('id', user.id).single();
        return { ...user, ...prof };
    }
};

const DB = {
    async getClientes(role, userId) {
        let q = _sb.from('clientes').select('*').order('nome');
        if (role === 'comercial') q = q.eq('criado_por', userId);
        const { data } = await q; return data || [];
    },
    async saveCliente(dados, userId) {
        const { error } = await _sb.from('clientes').insert([{ ...dados, criado_por: userId }]);
        return !error;
    },
    async getContactos(clienteId) {
        const { data } = await _sb.from('contactos').select('*').eq('cliente_id', clienteId);
        return data || [];
    }
};