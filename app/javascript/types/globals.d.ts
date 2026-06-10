import type { FlashData } from '@/types'

type CurrentUser = {
  id: number
  email: string
  full_name: string
  language: string
  avatar_url: string | null
  theme_preference: string | null
}

declare module '@inertiajs/core' {
  export interface InertiaConfig {
    sharedPageProps: {
      current_user: CurrentUser
      current_account: { id: number; name: string }
    }
    flashDataType: FlashData
    errorValueType: string[]
  }
}
