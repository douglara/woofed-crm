import { Briefcase, UserPlus, CalendarPlus, BarChart3 } from "lucide-react";
import { usePage } from "@inertiajs/react";
import type { ComponentType } from "react";

import WoofedIcon from "./WoofedIcon";

interface Suggestion {
  icon: ComponentType<{ className?: string }>;
  iconClass: string;
  title: string;
  sub: string;
  prompt: string;
}

const SUGGESTIONS: Suggestion[] = [
  {
    icon: Briefcase,
    iconClass: "color-fg-highlight bg-purple-200",
    title: "Create a deal",
    sub: "“R$ 15k for StartupX”",
    prompt: "Create a deal",
  },
  {
    icon: UserPlus,
    iconClass: "text-blue-600 color-bg-feedback-info-default",
    title: "Create a contact",
    sub: "“Beatriz, from Mercado Vivo”",
    prompt: "Create a contact",
  },
  {
    icon: CalendarPlus,
    iconClass: "color-fg-feedback-success color-bg-feedback-success-default",
    title: "Schedule an activity",
    sub: "“Meeting tomorrow at 10am”",
    prompt: "Schedule an activity",
  },
  {
    icon: BarChart3,
    iconClass: "text-red-600 bg-red-200",
    title: "Create a pipeline",
    sub: "“Sales pipeline for SaaS customers”",
    prompt: "Create a pipeline",
  },
];

// Empty conversation: greeting + a grid of one-tap example prompts.
const ChatBlankState = ({ onPick }: { onPick: (prompt: string) => void }) => {
  const { current_user } = usePage().props;
  const firstName = current_user.full_name.trim().split(" ")[0];

  return (
    <div className="flex flex-1 flex-col items-center justify-center px-8 text-center">
      <WoofedIcon size={64} />
      <h1 className="mb-1.5 mt-[18px] text-[1.625rem] font-extrabold text-gray-1100">
        Hi {firstName}! I&apos;m Woofed AI 👋
      </h1>
      <p className="mb-7 max-w-[460px] text-text font-medium leading-relaxed color-fg-soft">
        Your CRM copilot. Ask in natural language and I&apos;ll create deals,
        contacts and activities — you just confirm.
      </p>
      <div className="grid w-full max-w-[540px] grid-cols-2 gap-3">
        {SUGGESTIONS.map((s) => {
          const Icon = s.icon;
          return (
            <button
              key={s.title}
              type="button"
              onClick={() => onPick(s.prompt)}
              className="flex items-start gap-3 rounded-lg border-[1.5px] color-border-default color-bg-surface-default px-3.5 py-3 text-left transition-colors hover:color-border-harder"
            >
              <span
                className={`flex size-8 shrink-0 items-center justify-center rounded-md ${s.iconClass}`}
              >
                <Icon className="size-4" />
              </span>
              <div>
                <div className="mb-0.5 text-subtext font-bold text-gray-1100">
                  {s.title}
                </div>
                <div className="typography-micro-m text-gray-700">{s.sub}</div>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default ChatBlankState;
