import React, { useEffect, useState } from 'react';

interface LogoProps {
  customClass?: string;
}

const Logo: React.FC<LogoProps> = ({ customClass }) => {
  const [logo, setLogo] = useState<{ image?: string }>({});

  useEffect(() => {
    const fetchLogo = async () => {
      try {
        const response = await fetch('/logo/');
        const data = await response.json();
        setLogo(data);
      } catch (error) {
        console.error('Error fetching logo:', error);
      }
    };

    fetchLogo();
  }, []);

  return (
    <a href="/">
      {logo.image ? (
        <img
          src={logo.image}
          alt="Logo"
          className={customClass ? customClass : 'h-7 sm:h-8 object-contain'}
        />
      ) : (
        <img
          className="h-8 object-contain"
          src="/static/frontend/images/logo.png"
          alt="Logo"
        />
      )}
    </a>
  );
};

export default Logo;