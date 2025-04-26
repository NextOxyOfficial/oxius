import React, { useState, useEffect } from 'react';

interface ProductDetailsCard2Props {
  currentProduct: {
    name: string;
    image_details?: { image: string }[];
    sale_price?: number;
    regular_price?: number;
    quantity?: number;
    weight?: number;
    is_free_delivery?: boolean;
    short_description?: string;
    description?: string;
    benefits_title?: string;
    benefits?: { icon: string; title: string; description: string }[];
    faqs_title?: string;
    faqs_subtitle?: string;
    faqs?: { label: string; content: string; icon: string }[];
    cta_title?: string;
    cta_subtitle?: string;
    cta_button_text?: string;
    cta_button_subtext?: string;
    cta_badge1?: string;
    cta_badge2?: string;
    cta_badge3?: string;
    delivery_fee_inside_dhaka?: number;
    delivery_fee_outside_dhaka?: number;
    reviews?: { name: string; rating: number; comment: string; date?: string }[];
  };
}

const ProductDetailsCard2: React.FC<ProductDetailsCard2Props> = ({ currentProduct }) => {
  const [hideSticky, setHideSticky] = useState(true);
  const [lastScrollPosition, setLastScrollPosition] = useState(0);

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 200) {
        setHideSticky(false);
        if (window.scrollY < lastScrollPosition && window.scrollY < 50) {
          setHideSticky(true);
        }
        const bottomPosition = document.documentElement.scrollHeight - window.innerHeight - 300;
        if (window.scrollY > bottomPosition) {
          setHideSticky(true);
        }
      } else {
        setHideSticky(true);
      }
      setLastScrollPosition(window.scrollY);
    };

    window.addEventListener('scroll', handleScroll);
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, [lastScrollPosition]);

  const calculateDiscountPercentage = (regular: number, sale: number) => {
    if (!regular || !sale) return 0;
    return Math.round(((regular - sale) / regular) * 100);
  };

  return (
    <div className="product-sales-funnel w-full">
      <section className="hero-section bg-gradient-to-br from-slate-900 to-slate-800 text-white rounded-xl overflow-hidden w-full">
        <div className="px-6 py-2 md:py-20 w-full">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
            <div className="relative order-2 md:order-1">
              <div className="aspect-square rounded-xl overflow-hidden bg-white/10 backdrop-blur-sm p-6 shadow-2xl relative">
                {currentProduct.image_details?.[0]?.image && (
                  <img
                    src={currentProduct.image_details[0].image}
                    alt={currentProduct.name}
                    className="w-full h-full object-contain"
                  />
                )}
                {currentProduct.sale_price && currentProduct.regular_price && (
                  <div className="absolute top-4 right-4 bg-red-500 text-white text-sm font-bold px-3 py-1.5 rounded-full shadow-lg animate-pulse">
                    SAVE {calculateDiscountPercentage(currentProduct.regular_price, currentProduct.sale_price)}%
                  </div>
                )}
              </div>
            </div>
            <div className="order-1 md:order-2">
              <h1 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4">{currentProduct.name}</h1>
              <p className="text-lg text-white/80 mb-6">
                {currentProduct.short_description ||
                  'Experience the ultimate product designed to transform your life. Premium quality, outstanding performance, and exceptional value.'}
              </p>
              <div className="flex items-baseline mb-8">
                <span className="text-4xl font-bold text-white">
                  ৳{currentProduct.sale_price || currentProduct.regular_price}
                </span>
                {currentProduct.regular_price && currentProduct.sale_price && (
                  <span className="text-lg text-white/60 line-through ml-2">
                    ৳{currentProduct.regular_price}
                  </span>
                )}
              </div>
              <button className="w-full md:w-auto px-8 py-4 bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white text-lg font-bold rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 focus:ring-4 focus:ring-primary-500/50 flex items-center justify-center gap-3 group">
                Buy Now
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default ProductDetailsCard2;