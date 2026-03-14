"use client";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { ArrowUpIcon, CircleStopIcon } from "lucide-react";
import type { ComponentProps, FormEvent } from "react";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
} from "react";

// ── Types ─────────────────────────────────────────────────────────────────────

export interface PromptInputMessage {
  text: string;
  files?: File[];
}

interface PromptInputContextValue {
  isLoading: boolean;
  valueRef: React.MutableRefObject<string>;
}

// ── Context ───────────────────────────────────────────────────────────────────

const PromptInputContext = createContext<PromptInputContextValue>({
  isLoading: false,
  valueRef: { current: "" },
});

const usePromptInputContext = () => useContext(PromptInputContext);

// Keep hook name stable for external consumers (used by PromptInputActionAddAttachments etc.)
export const usePromptInputAttachments = () =>
  useMemo(() => ({ files: [] as File[], remove: (_id: string) => {} }), []);

// ── PromptInput (root) ────────────────────────────────────────────────────────

export type PromptInputProps = ComponentProps<"form"> & {
  isLoading?: boolean;
  /** Called when the form is submitted. Receives { text, files }. */
  onSubmit?: (message: PromptInputMessage) => void;
  /** Allows global drag-and-drop of files onto the form. */
  globalDrop?: boolean;
  /** Allows multiple file attachments. */
  multiple?: boolean;
};

export const PromptInput = ({
  isLoading = false,
  onSubmit,
  className,
  children,
  globalDrop: _globalDrop,
  multiple: _multiple,
  ...props
}: PromptInputProps) => {
  const valueRef = useRef<string>("");

  const handleSubmit = useCallback(
    (e: FormEvent<HTMLFormElement>) => {
      e.preventDefault();
      if (!isLoading && valueRef.current.trim()) {
        onSubmit?.({ text: valueRef.current });
      }
    },
    [isLoading, onSubmit]
  );

  const ctx = useMemo<PromptInputContextValue>(
    () => ({ isLoading, valueRef }),
    [isLoading]
  );

  return (
    <PromptInputContext.Provider value={ctx}>
      <form
        onSubmit={handleSubmit}
        className={cn(
          "flex w-full flex-col rounded-xl border border-input bg-background shadow-xs",
          className
        )}
        {...props}
      >
        {children}
      </form>
    </PromptInputContext.Provider>
  );
};

// ── PromptInputHeader ─────────────────────────────────────────────────────────

export type PromptInputHeaderProps = ComponentProps<"div">;

export const PromptInputHeader = ({
  className,
  ...props
}: PromptInputHeaderProps) => (
  <div className={cn("px-4 pt-3", className)} {...props} />
);

// ── PromptInputBody ───────────────────────────────────────────────────────────

export type PromptInputBodyProps = ComponentProps<"div">;

export const PromptInputBody = ({
  className,
  ...props
}: PromptInputBodyProps) => (
  <div className={cn("min-h-0 px-4 py-2", className)} {...props} />
);

// ── PromptInputFooter ─────────────────────────────────────────────────────────

export type PromptInputFooterProps = ComponentProps<"div">;

export const PromptInputFooter = ({
  className,
  ...props
}: PromptInputFooterProps) => (
  <div
    className={cn(
      "flex items-center justify-between gap-2 px-4 pb-3",
      className
    )}
    {...props}
  />
);

// ── PromptInputTools ──────────────────────────────────────────────────────────

export type PromptInputToolsProps = ComponentProps<"div">;

export const PromptInputTools = ({
  className,
  ...props
}: PromptInputToolsProps) => (
  <div className={cn("flex items-center gap-1", className)} {...props} />
);

// ── PromptInputTextarea ───────────────────────────────────────────────────────

export type PromptInputTextareaProps = ComponentProps<"textarea">;

export const PromptInputTextarea = ({
  className,
  onChange,
  ...props
}: PromptInputTextareaProps) => {
  const ref = useRef<HTMLTextAreaElement>(null);
  const { isLoading, valueRef } = usePromptInputContext();

  // Keep the valueRef in sync with the controlled value
  useEffect(() => {
    if (typeof props.value === "string") {
      valueRef.current = props.value;
    }
  }, [props.value, valueRef]);

  // Auto-resize
  useEffect(() => {
    const ta = ref.current;
    if (!ta) return;
    ta.style.height = "auto";
    ta.style.height = `${Math.min(ta.scrollHeight, 200)}px`;
  }, [props.value]);

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      valueRef.current = e.target.value;
      onChange?.(e);
    },
    [onChange, valueRef]
  );

  return (
    <textarea
      ref={ref}
      rows={1}
      disabled={isLoading}
      className={cn(
        "min-h-[24px] w-full resize-none bg-transparent text-sm leading-relaxed outline-none",
        "placeholder:text-muted-foreground disabled:opacity-50",
        className
      )}
      onChange={handleChange}
      {...props}
    />
  );
};

// ── PromptInputSubmit ─────────────────────────────────────────────────────────

export type SubmitStatus = "submitted" | "streaming" | "ready" | "error";

export type PromptInputSubmitProps = Omit<
  ComponentProps<typeof Button>,
  "type"
> & {
  status?: SubmitStatus;
};

export const PromptInputSubmit = ({
  className,
  status = "ready",
  disabled,
  ...props
}: PromptInputSubmitProps) => {
  const isActive = status === "streaming" || status === "submitted";

  return (
    <Button
      type="submit"
      size="icon-sm"
      disabled={disabled ?? false}
      className={cn(
        "shrink-0 rounded-lg transition-all duration-200",
        isActive
          ? "bg-foreground text-background hover:bg-foreground/80"
          : "bg-foreground text-background hover:bg-foreground/80 disabled:opacity-30",
        className
      )}
      {...props}
    >
      {isActive ? <CircleStopIcon size={16} /> : <ArrowUpIcon size={16} />}
      <span className="sr-only">{isActive ? "Parar" : "Enviar"}</span>
    </Button>
  );
};

// ── PromptInputButton ─────────────────────────────────────────────────────────

export type PromptInputButtonProps = ComponentProps<typeof Button>;

export const PromptInputButton = ({
  className,
  ...props
}: PromptInputButtonProps) => (
  <Button
    type="button"
    size="sm"
    variant="ghost"
    className={cn(
      "h-8 gap-1.5 px-2 text-muted-foreground hover:text-foreground",
      className
    )}
    {...props}
  />
);

// ── Stub exports for future/optional components ───────────────────────────────
// These keep the import surface compatible with the full ai-elements API.

export const PromptInputActionMenu = ({
  children,
  ...props
}: ComponentProps<"div">) => <div {...props}>{children}</div>;

export const PromptInputActionMenuTrigger = (props: ComponentProps<"div">) => (
  <div {...props} />
);

export const PromptInputActionMenuContent = ({
  children,
  ...props
}: ComponentProps<"div">) => <div {...props}>{children}</div>;

export const PromptInputActionAddAttachments = (
  props: ComponentProps<"div">
) => <div {...props} />;
