export interface Env {
  DATABASE_URL: string;
  GEMINI_API_KEY: string;
  ENVIRONMENT: string;
}

export interface User {
  id: string;
  device_id: string;
  created_at: string;
  updated_at: string;
}

export interface UserPreference {
  id: string;
  user_id: string;
  voice_speed: number;
  voice_pitch: number;
  description_detail: string;
  language: string;
  vibration_enabled: boolean;
  high_contrast_enabled: boolean;
  enabled_features: string[];
  emergency_contact: string | null;
}

export interface Session {
  id: string;
  user_id: string;
  started_at: string;
  ended_at: string | null;
  location: string | null;
  session_type: string;
}

export interface UsageStat {
  id: string;
  user_id: string;
  feature: string;
  timestamp: string;
  duration: number | null;
  success: boolean;
  error_message: string | null;
}
