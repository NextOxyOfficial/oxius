import React, { useState, useEffect } from 'react';

const TranslateHandler: React.FC = () => {
  const languageOptions = [
    { value: 'en', label: 'English', icon: '🇺🇸' },
    { value: 'bn', label: 'বাংলা', icon: '🇧🇩' },
  ];

  const [currentLanguage, setCurrentLanguage] = useState(languageOptions[1]);

  useEffect(() => {
    const savedLanguage = localStorage.getItem('language');
    if (savedLanguage) {
      const foundLanguage = languageOptions.find(
        (lang) => lang.value === savedLanguage
      );
      if (foundLanguage) {
        setCurrentLanguage(foundLanguage);
      }
    } else {
      setCurrentLanguage(languageOptions[1]);
    }
  }, []);

  useEffect(() => {
    localStorage.setItem('language', currentLanguage.value);
    // Simulate setting locale in an i18n library
    console.log(`Locale set to: ${currentLanguage.value}`);
  }, [currentLanguage]);

  return (
    <div>
      <select
        value={currentLanguage.value}
        onChange={(e) => {
          const selectedLanguage = languageOptions.find(
            (lang) => lang.value === e.target.value
          );
          if (selectedLanguage) {
            setCurrentLanguage(selectedLanguage);
          }
        }}
        className="sm:w-32"
      >
        {languageOptions.map((language) => (
          <option key={language.value} value={language.value}>
            {language.label}
          </option>
        ))}
      </select>
    </div>
  );
};

export default TranslateHandler;