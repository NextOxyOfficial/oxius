import { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/router';
import Cookies from 'js-cookie';
import { useApi } from './useApi';

interface User {
  access: string;
  user: {
    username: string;
    user_type: string;
    is_superuser: boolean;
  };
  face?: boolean;
}

interface LoginResponse {
  error?: any;
  loggedIn?: boolean;
  user_type?: string;
  is_superuser?: boolean;
}

export function useAuth() {
  const { get, post } = useApi();
  const [user, setUser] = useState<User | null>(null);
  const [notifs, setNotifs] = useState<any[]>([]);
  const router = useRouter();
  
  const isAuthenticated = useMemo(() => user !== null, [user]);

  const jwtLogin = async (): Promise<boolean> => {
    const jwt = Cookies.get('adsyclub-jwt');
    
    if (!jwt) {
      setUser(null);
      return false;
    }
    
    try {
      const { data, error } = await get<User>('/auth/validate-token/');
      
      if (error || !data) {
        throw new Error('JWT validation failed');
      }
      
      setUser(data);
      
      Cookies.set('adsyclub-jwt', data.access);
      
      if (data.face) {
        Cookies.set('username', data.user.username);
      }
      
      return true;
    } catch (error) {
      console.log("JWT validation error:", error);
      setUser(null);
      Cookies.remove('adsyclub-jwt');
      return false;
    }
  };

  const login = async (email: string, password: string): Promise<LoginResponse> => {
    try {
      const { data, error } = await post<User>('/auth/login/', { email, password });
      
      if (error || !data) {
        return { error };
      }
      
      setUser(data);
      
      Cookies.set('adsyclub-jwt', data.access);
      
      if (data.face) {
        Cookies.set('username', data.user.username);
      }
      
      return {
        loggedIn: true,
        user_type: data.user.user_type,
        is_superuser: data.user.is_superuser,
      };
    } catch (err) {
      console.log("Error during login:", err);
      return { error: err };
    }
  };

  const logout = async (): Promise<void> => {
    setUser(null);
    Cookies.remove('adsyclub-jwt');
    router.push('/');
  };

  return {
    user,
    isAuthenticated,
    jwtLogin,
    login,
    logout,
    notifs,
  };
}