import { router } from '@inertiajs/react'
import { Plus } from 'lucide-react'

import { Button } from '@/components/ui/button'

// Starts a fresh session. The server generates a new id and reloads the page
// blank on it; the previous session is abandoned (the user only works on the
// latest one).
const NewSessionButton = ({ sessionsUrl }: { sessionsUrl: string }) => (
  <Button
    type="button"
    variant="outline"
    size="sm"
    onClick={() => router.post(sessionsUrl)}
  >
    <Plus className="size-4" />
    New session
  </Button>
)

export default NewSessionButton
