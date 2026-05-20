import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

export async function createLink(url) {
  const { data } = await api.post('/links', { url })
  return data
}

export async function listLinks() {
  const { data } = await api.get('/links')
  return data
}

export async function checkHealth() {
  const { data } = await api.get('/health')
  return data
}
