import { defineStore } from "pinia";

export const useStoreCart = defineStore("cart", {
  state: () => ({
    products: [] as Array<Product>,
  }),

  getters: {
    totalPrice: (state) =>
      state.products.reduce(
        (acc: number, product) => acc + product.sale_price * product.count,
        0
      ),

    totalDiscountPrice: (state) =>
      state.products.reduce(
        (acc: number, product) => acc + product.sale_price * product.count,
        0
      ),
  },

  actions: {
    addProduct(product: Product, count: number) {
      const isInList = this.products.find((p) => p.id === product.id);
      if (isInList) {
        return;
      } else {
        this.products.push({ ...product, count });
      }
    },
    removeProduct(productId: string) {
      this.products = this.products.filter(
        (product) => product.id !== productId
      );
    },
    increaseCartItem(id: string) {
      const index = this.products.findIndex((p) => p.id === id);
      if (index !== -1) {
        const updatedProduct = {
          ...this.products[index],
          count: this.products[index].count + 1,
        };
        this.products.splice(index, 1, updatedProduct);
      }
      this.totalPrice;
      this.totalDiscountPrice;
    },
    decreaseCartItem(id: string) {
      const index = this.products.findIndex((p) => p.id === id);
      if (index !== -1 && this.products[index].count > 1) {
        const updatedProduct = {
          ...this.products[index],
          count: this.products[index].count - 1,
        };

        this.products.splice(index, 1, updatedProduct);
      } else if (index !== -1 && this.products[index].count === 1) {
        // this.products.splice(index, 1);
      }
    },
    clearCart() {
      this.products = [];
    },
  },
});

interface Product {
  id: string;
  name?: string;
  owner?: string;
  category?: string;
  description?: string;
  short_description?: string;
  image: string;
  price: number;
  rating?: number;
  quantity?: number;
  count: number;
  product_price: number;
  discount_price: number;
  sale_price: number;
  weight: number;
  delivery_information: string;
  delivery_fee_free: number;
  delivery_fee_inside_dhaka: number;
  delivery_fee_outside_dhaka: number;
}
