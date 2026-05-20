<script setup>
import { onMounted, ref } from 'vue'
import { createLink, listLinks } from './api'

const url = ref('')
const links = ref([])
const loading = ref(false)
const error = ref('')
const success = ref('')

async function loadLinks() {
  try {
    links.value = await listLinks()
  } catch (e) {
    error.value = '加载链接列表失败'
  }
}

async function handleSubmit() {
  error.value = ''
  success.value = ''

  if (!url.value.trim()) {
    error.value = '请输入原始 URL'
    return
  }

  loading.value = true
  try {
    const link = await createLink(url.value.trim())
    success.value = `短链接已生成：${link.short_url}`
    url.value = ''
    await loadLinks()
  } catch (e) {
    error.value = e.response?.data?.error || '生成失败，请检查 URL 是否正确'
  } finally {
    loading.value = false
  }
}

async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text)
    success.value = '已复制到剪贴板'
  } catch {
    error.value = '复制失败'
  }
}

onMounted(loadLinks)
</script>

<template>
  <div class="page">
    <header class="hero">
      <h1>短链接生成器</h1>
      <p>输入长链接，一键生成短链接并统计点击次数</p>
    </header>

    <section class="card form-card">
      <form @submit.prevent="handleSubmit">
        <label for="url">原始 URL</label>
        <div class="input-row">
          <input
            id="url"
            v-model="url"
            type="url"
            placeholder="https://example.com/very/long/path"
            :disabled="loading"
          />
          <button type="submit" :disabled="loading">
            {{ loading ? '生成中...' : '生成短链' }}
          </button>
        </div>
      </form>

      <p v-if="error" class="message error">{{ error }}</p>
      <p v-if="success" class="message success">{{ success }}</p>
    </section>

    <section class="card">
      <div class="section-head">
        <h2>已生成的链接</h2>
        <button class="ghost" type="button" @click="loadLinks">刷新</button>
      </div>

      <div v-if="links.length === 0" class="empty">暂无数据，先生成一个短链接吧</div>

      <table v-else>
        <thead>
          <tr>
            <th>短链接</th>
            <th>原始 URL</th>
            <th>点击</th>
            <th>创建时间</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="link in links" :key="link.id">
            <td>
              <a :href="link.short_url" target="_blank" rel="noopener">{{ link.short_url }}</a>
            </td>
            <td class="truncate" :title="link.original_url">{{ link.original_url }}</td>
            <td>{{ link.click_count }}</td>
            <td>{{ new Date(link.created_at).toLocaleString() }}</td>
            <td>
              <button class="ghost" type="button" @click="copyText(link.short_url)">复制</button>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>
