import React, { useEffect, useState } from 'react';

interface StateSelectProps {
  modelValue: string;
  onUpdate: (value: string) => void;
}

const StateSelect: React.FC<StateSelectProps> = ({ modelValue, onUpdate }) => {
  const [state, setState] = useState(modelValue);
  const [regions, setRegions] = useState<{ name: string }[]>([]);

  useEffect(() => {
    const fetchRegions = async () => {
      try {
        const response = await fetch('/cities-light/regions/?country=Bangladesh');
        const data = await response.json();
        setRegions(data);
      } catch (error) {
        console.error('Error fetching regions:', error);
      }
    };

    fetchRegions();
  }, []);

  useEffect(() => {
    onUpdate(state);
  }, [state, onUpdate]);

  return (
    <div>
      <label htmlFor="state-select" className="block text-sm font-medium text-gray-700">
        State
      </label>
      <select
        id="state-select"
        value={state}
        onChange={(e) => setState(e.target.value)}
        className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
      >
        <option value="" disabled>
          Select a state
        </option>
        {regions.map((region) => (
          <option key={region.name} value={region.name}>
            {region.name}
          </option>
        ))}
      </select>
    </div>
  );
};

export default StateSelect;