<script setup>
defineProps(["percentage"])
</script>

<template>
  <svg height="1em" width="1em" viewBox="0 0 20 20" class="me-1">
    <circle
      r="10"
      cx="10"
      cy="10"
      fill="white"
      stroke="#ccc"
      stroke-width="1"
    />
    <circle :r="(10 * percentage) / 100" cx="10" cy="10" fill="blue" />
  </svg>
</template>
