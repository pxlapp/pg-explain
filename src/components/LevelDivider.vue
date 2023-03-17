<script lang="ts" setup>
import _ from "lodash"
interface Props {
  level: number
  isSubplan: boolean
  isNode?: boolean
  isLastChild: boolean
  branches: number[]
  index: number
}
defineProps<Props>()
</script>
<template>
  <span class="tree-lines">
    <template v-for="i in _.range(level)">
      <template v-if="_.indexOf(branches, i) != -1">&emsp;│</template
      ><template v-else-if="i !== 0">&emsp;&emsp;</template> </template
    ><template v-if="index !== 0">
      <template v-if="!(isSubplan && isNode)">{{
        isLastChild ? "&emsp;└" : "&emsp;├"
      }}</template
      ><template v-else>
        <template v-if="!isLastChild">&emsp;│</template
        ><template v-else>&emsp;&emsp;</template>
      </template>
    </template>
  </span>
</template>
