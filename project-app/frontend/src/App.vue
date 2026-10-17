<script setup>
import { onMounted, ref } from "vue";

const customers = ref([]);
const name = ref("");
const error = ref("");

async function loadCustomers() {
  const response = await fetch("/api/customers");
  if (!response.ok) throw new Error("顧客データを取得できませんでした");
  customers.value = await response.json();
}

async function addCustomer() {
  const response = await fetch("/api/customers", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: name.value }),
  });
  if (!response.ok) {
    error.value = "顧客を登録できませんでした";
    return;
  }
  name.value = "";
  error.value = "";
  await loadCustomers();
}

onMounted(() =>
  loadCustomers().catch(() => {
    error.value = "APIに接続できません";
  }),
);
</script>

<template>
  <main class="page-shell">
    <header class="topbar"><span class="mark">CP</span><span>顧客管理</span><span class="env">DEV</span></header>
    <section class="content">
      <p class="eyebrow">CUSTOMER OPERATIONS</p>
      <h1>顧客一覧</h1>
      <p class="lede">登録済みの顧客情報を管理します。</p>
      <form class="add-form" @submit.prevent="addCustomer">
        <label for="customer-name">顧客名</label>
        <input id="customer-name" v-model="name" required maxlength="100" placeholder="例: 青空商事" />
        <button type="submit">登録する</button>
      </form>
      <p v-if="error" role="alert" class="error">{{ error }}</p>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>顧客名</th>
              <th>登録状態</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="customer in customers" :key="customer.id">
              <td>{{ customer.id }}</td>
              <td>{{ customer.name }}</td>
              <td><span class="status">有効</span></td>
            </tr>
            <tr v-if="customers.length === 0">
              <td colspan="3" class="empty">顧客データはありません</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </main>
</template>
