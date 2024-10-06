<script setup>
import ModalAdd from "./components/ModalAdd.vue";
import {provide, ref} from "vue";
import axios from "axios";

const props = defineProps({
  offers: Array
})

const offersList = ref(props.offers)

const updateOfferList = (newOffer) => {
  offersList.value.push(newOffer.value)
}

const removeOffer = async (id) => {
  offersList.value = offersList.value.filter((offer) => {
    if (offer.id !== id) {
      return offer
    }
  })

  await axios.delete('offer/detete/' + id)
}

provide("updateOfferList", updateOfferList)
</script>

<template>
  <button data-modal-target="crud-modal" data-modal-toggle="crud-modal"
          class="mt-5 mx-auto block text-white bg-indigo-500 hover:bg-indigo-800 focus:ring-4 focus:outline-none focus:ring-indigo-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-indigo-600 dark:hover:bg-indigo-500 dark:focus:ring-indigo-800"
          type="button">
    Ajouter une offre
  </button>
  <div class="flex justify-center gap-6 flex-wrap mt-10">
    <article
        v-for="offer in offersList"
        class="w-72 bg-white group relative rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transform duration-200 ">
      <div class="relative w-72 h-44">
        <img
            :src="offer.img ?? 'https://ralfvanveen.com/wp-content/uploads/2021/06/Espace-r%C3%A9serv%C3%A9-_-Glossaire.svg'"
            alt="Desk with leather desk pad, walnut desk organizer, wireless keyboard and mouse, and porcelain mug."
            class="w-72 h-48 object-center object-cover">
      </div>
      <div class="px-5 py-4">
        <h3 class="text-3xl font-bold mt-2 pb-2">
          {{ offer.name }}
        </h3>
        <p>{{ offer.address }}</p>
        <p>{{ offer.duration }}</p>
        <p>{{ offer.pricing }} € / heures</p>
        <div class="flex items-center justify-between">
          <button
              class="mt-3 text-white bg-indigo-500 hover:bg-indigo-800 focus:ring-4 focus:ring-indigo-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-indigo-600 dark:hover:bg-indigo-500 focus:outline-none dark:focus:ring-indigo-800">
            Voir plus
          </button>
          <button @click="removeOffer(offer.id)"
                  class="text-white bg-red-700 hover:bg-red-800 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-lg text-sm p-2.5 text-center inline-flex items-center me-2 dark:bg-red-600 dark:hover:bg-red-700 dark:focus:ring-red-800">
            <i class="fa-solid fa-trash"></i>
            <span class="sr-only">Icon description</span>
          </button>
        </div>
      </div>
    </article>
    <modal-add></modal-add>
  </div>
</template>
