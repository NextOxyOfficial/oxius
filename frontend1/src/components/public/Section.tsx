import React from 'react';

const Section: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return <section className="py-2 md:py-6">{children}</section>;
};

export default Section;