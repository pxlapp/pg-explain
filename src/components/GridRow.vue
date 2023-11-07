<script lang="ts" setup>
import { inject, provide, reactive, ref } from "vue"
import type { Ref } from "vue"
import type { IPlan, Node, ViewOptions } from "@/interfaces"
import { EstimateDirection, NodeProp } from "@/enums"
import { PlanKey, ViewOptionsKey } from "@/symbols"
import {
  blocks,
  blocksAsBytes,
  duration,
  factor,
  keysToString,
  sortKeys,
} from "@/filters"
import LevelDivider from "@/components/LevelDivider.vue"
import PlanNodeDetail from "@/components/PlanNodeDetail.vue"
import ProgressPie from "@/components/ProgressPie.vue"
import useNode from "@/node"

interface Props {
  node: Node
  level: number
  isSubplan: boolean
  isLastChild: boolean
  branches: number[]
  index: number
  columns: string[]
}
const props = defineProps<Props>()

const node = reactive<Node>(props.node)
const plan = inject(PlanKey) as Ref<IPlan>
const viewOptions = inject(ViewOptionsKey) as ViewOptions

const {
  estimateFactorPercent,
  rowsRemoved,
  rowsRemovedPercent,
  rowsRemovedPercentString,
  sharedHitPercent,
  sharedReadPercent,
  sharedDirtiedPercent,
  sharedWrittenPercent,
  tempReadPercent,
  tempWrittenPercent,
  localHitPercent,
  localReadPercent,
  localDirtiedPercent,
  localWrittenPercent,
} = useNode(plan, node, viewOptions)
const showDetails = ref<boolean>(false)
provide("updateSize", () => undefined)
</script>
<template>
  <tr @click="showDetails = !showDetails" class="node">
    <td class="node-index text-muted">
      <!-- node id -->
      <span class="font-weight-normal">#{{ node.nodeId }} </span>
    </td>
    <td class="text-nowrap">
      <div class="d-flex justify-content-between">
        <ProgressPie
          :percentage="
            (node[NodeProp.EXCLUSIVE_DURATION] /
              (plan.planStats.executionTime ||
                plan.content.Plan[NodeProp.ACTUAL_TOTAL_TIME])) *
            100
          "
        ></ProgressPie>
        <!-- time -->
        {{ duration(node[NodeProp.EXCLUSIVE_DURATION]) }}
      </div>
    </td>
    <td class="text-nowrap">
      <div class="d-flex justify-content-between">
        <ProgressPie
          :percentage="
            (node[NodeProp.ACTUAL_ROWS_REVISED] / plan.planStats.maxRows) * 100
          "
        ></ProgressPie>
        <!-- rows -->
        {{ node[NodeProp.ACTUAL_ROWS_REVISED].toLocaleString() }}
      </div>
    </td>
    <td class="text-nowrap">
      <div
        v-if="node[NodeProp.PLANNER_ESTIMATE_FACTOR] != 1"
        class="d-flex justify-content-between"
      >
        <ProgressPie :percentage="estimateFactorPercent"></ProgressPie>
        <!-- estimation -->
        <span v-if="node[NodeProp.PLANNER_ESTIMATE_FACTOR] != 1">
          <span
            v-html="factor(node[NodeProp.PLANNER_ESTIMATE_FACTOR] || 0)"
          ></span>
          <span
            v-if="
              node[NodeProp.PLANNER_ESTIMATE_DIRECTION] ===
              EstimateDirection.under
            "
          >
            ↓
          </span>
          <span
            v-if="
              node[NodeProp.PLANNER_ESTIMATE_DIRECTION] ===
              EstimateDirection.over
            "
          >
            ↑
          </span>
        </span>
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('loops')">
      <!-- loops -->
      <span v-if="node[NodeProp.ACTUAL_LOOPS] != 1">
        {{ node[NodeProp.ACTUAL_LOOPS] }}
      </span>
    </td>
    <td class="text-nowrap" v-if="columns.includes('filter')">
      <!-- filter -->
      <div v-if="rowsRemoved" class="d-flex justify-content-between">
        <ProgressPie :percentage="rowsRemovedPercent"></ProgressPie>
        <span>{{ rowsRemovedPercentString }}%</span>
      </div>
    </td>
    <td
      class="node-type"
      style="
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        max-width: 0;
      "
    >
      <level-divider
        :isSubplan="isSubplan"
        isNode
        :isLastChild="isLastChild"
        :level="level"
        :branches="branches"
        :index="index"
      ></level-divider>
      <div class="d-inline">
        <b
          class="border border-secondary px-1 bg-light"
          style="--bs-border-opacity: 0.5"
        >
          {{ node[NodeProp.NODE_TYPE] }}
        </b>

        <span class="text-secondary">
          <template v-if="node[NodeProp.RELATION_NAME]">
            <span class="text-muted">on</span>
            <span v-if="node[NodeProp.SCHEMA]"
              >{{ node[NodeProp.SCHEMA] }}.</span
            >{{ node[NodeProp.RELATION_NAME] }}
            <span v-if="node[NodeProp.ALIAS]">
              <span class="text-muted">as</span>
              {{ node[NodeProp.ALIAS] }}
            </span>
          </template>
          <template v-else-if="node[NodeProp.ALIAS]">
            <span class="text-muted">on</span>
            <span v-html="keysToString(node[NodeProp.ALIAS] as string)"></span>
          </template>
          <template v-if="node[NodeProp.GROUP_KEY]">
            <span class="text-muted">by</span>
            <span
              v-html="keysToString(node[NodeProp.GROUP_KEY] as string)"
            ></span>
          </template>
          <template v-if="node[NodeProp.SORT_KEY]">
            <span class="text-muted">by</span>
            <span
              v-html="
                      sortKeys(
                        node[NodeProp.SORT_KEY] as string[],
                        node[NodeProp.PRESORTED_KEY] as string[]
                      )
                    "
            ></span>
          </template>
          <template v-if="node[NodeProp.JOIN_TYPE]">
            {{ node[NodeProp.JOIN_TYPE] }}
            <span class="text-muted">join</span>
          </template>
          <template v-if="node[NodeProp.INDEX_NAME]">
            <span class="text-muted">using</span>
            <span
              v-html="keysToString(node[NodeProp.INDEX_NAME] as string)"
            ></span>
          </template>
          <template v-if="node[NodeProp.HASH_CONDITION]">
            <span class="text-muted">on</span>
            <span
              v-html="keysToString(node[NodeProp.HASH_CONDITION] as string)"
            ></span>
          </template>
          <template v-if="node[NodeProp.CTE_NAME]">
            <span class="text-reset">
              <span class="text-muted">CTE</span>
              {{ node[NodeProp.CTE_NAME] }}
            </span>
          </template>
        </span>
      </div>
      <br />
      <div
        class="plan-node position-relative detailed"
        v-if="showDetails"
        style="width: 100%"
        @click.stop
      >
        <div class="plan-node-body card">
          <plan-node-detail :node="node"></plan-node-detail>
        </div>
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('shared.hit')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="sharedHitPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_SHARED_HIT_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_SHARED_HIT_BLOCKS]) }}
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('shared.read')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="sharedReadPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_SHARED_READ_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_SHARED_READ_BLOCKS]) }}
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('shared.dirtied')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="sharedDirtiedPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_SHARED_DIRTIED_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_SHARED_DIRTIED_BLOCKS]) }}
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('shared.written')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="sharedWrittenPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_SHARED_WRITTEN_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_SHARED_WRITTEN_BLOCKS]) }}
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('temp.read')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="tempReadPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_TEMP_READ_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_TEMP_READ_BLOCKS]) }}
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('temp.written')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="tempWrittenPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_TEMP_WRITTEN_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_TEMP_WRITTEN_BLOCKS]) }}
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('local.hit')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="localHitPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_LOCAL_HIT_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_LOCAL_HIT_BLOCKS]) }}
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('local.read')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="localReadPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_LOCAL_READ_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_LOCAL_READ_BLOCKS]) }}
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('local.dirtied')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="localDirtiedPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_LOCAL_DIRTIED_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_LOCAL_DIRTIED_BLOCKS]) }}
      </div>
    </td>
    <td class="text-end text-nowrap" v-if="columns.includes('local.written')">
      <div class="d-flex justify-content-between">
        <ProgressPie :percentage="localWrittenPercent"></ProgressPie>
        {{ blocks(node[NodeProp.EXCLUSIVE_LOCAL_WRITTEN_BLOCKS]) }}
      </div>
      <div v-if="showDetails" class="small">
        {{ blocksAsBytes(node[NodeProp.EXCLUSIVE_LOCAL_WRITTEN_BLOCKS]) }}
      </div>
    </td>
  </tr>
</template>
