<script setup>
defineProps(["percentage"])
</script>

<template>
  <div class="grid-progress progress rounded-0 bg-transparent">
    <div
      class="bg-primary border-primary"
      :style="{
        width: percentage + '%',
      }"
    ></div>
  </div>
</template>
