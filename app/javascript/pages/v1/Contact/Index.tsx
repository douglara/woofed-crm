/**
 * DynamicCombobox Usage Examples
 *
 * Este arquivo demonstra como usar o componente DynamicCombobox
 * em diferentes cenários com Inertia + React + Ransack.
 */

import * as React from "react";
import { useForm } from "@inertiajs/react";
import { DynamicCombobox } from "@/components/ui/dynamic-combobox";

// =============================================================================
// Página principal (default export para Inertia)
// =============================================================================
export default function Index() {
  // Exemplo: accountId fixo ou vindo de props
  const accountId = 1;

  return (
    <div className="p-6 space-y-8">
      <h1 className="text-2xl font-bold"></h1>

      <div className="space-y-4">
        <h2 className="text-lg font-semibold">Busca de Contatos</h2>
        <ContactComboboxExample accountId={accountId} />
      </div>

      <div className="space-y-4">
        <h2 className="text-lg font-semibold">Busca de Usuários</h2>
        <UserComboboxExample accountId={accountId} />
      </div>

      {/* <div className="space-y-4">
        <h2 className="text-lg font-semibold">Form com Combobox</h2>
        <DealFormExample accountId={accountId} />
      </div> */}
    </div>
  );
}

// =============================================================================
// EXEMPLO 1: Busca de Contatos
// =============================================================================
export function ContactComboboxExample({ accountId }: { accountId: number }) {
  const [selectedContact, setSelectedContact] = React.useState<number | null>(
    null,
  );

  return (
    <DynamicCombobox
      value={selectedContact}
      onChange={(value) => setSelectedContact(value as number)}
      endpoint={`/inertia/accounts/${accountId}/contacts/search`}
      searchKey="full_name_or_email_cont" // Ransack: busca por nome OU email
      labelKey="full_name"
      valueKey="id"
      placeholder="Buscar contato..."
      emptyMessage="Nenhum contato encontrado."
    />
  );
}

// =============================================================================
// EXEMPLO 2: Busca de Usuários
// =============================================================================
export function UserComboboxExample({ accountId }: { accountId: number }) {
  const [selectedUser, setSelectedUser] = React.useState<number | null>(null);

  return (
    <DynamicCombobox
      value={selectedUser}
      onChange={(value) => setSelectedUser(value as number)}
      endpoint={`/inertia/accounts/${accountId}/users/search`}
      searchKey="full_name_or_email_cont"
      labelKey="full_name"
      valueKey="id"
      placeholder="Buscar usuário..."
      emptyMessage="Nenhum usuário encontrado."
    />
  );
}

// =============================================================================
// EXEMPLO 3: Dentro de um Form Inertia
// =============================================================================
interface DealFormProps {
  accountId: number;
}

// export function DealFormExample({ accountId }: DealFormProps) {
//   const { data, setData, post, processing, errors } = useForm({
//     title: "",
//     contact_id: null as number | null,
//     assignee_id: null as number | null,
//     value: 0,
//   });

//   const handleSubmit = (e: React.FormEvent) => {
//     e.preventDefault();
//     post(`/accounts/${accountId}/deals`);
//   };

//   return (
//     <form onSubmit={handleSubmit} className="space-y-4">
//       <div>
//         <label className="block text-sm font-medium mb-1">Título</label>
//         <input
//           type="text"
//           value={data.title}
//           onChange={(e) => setData("title", e.target.value)}
//           className="w-full border rounded-lg px-3 py-2"
//         />
//         {errors.title && (
//           <span className="text-red-500 text-sm">{errors.title}</span>
//         )}
//       </div>

//       <div>
//         <label className="block text-sm font-medium mb-1">Contato</label>
//         <DynamicCombobox
//           value={data.contact_id}
//           onChange={(value) => setData("contact_id", value as number)}
//           endpoint={`/inertia/accounts/${accountId}/contacts/search`}
//           searchKey="full_name_or_email_or_phone_cont"
//           labelKey="full_name"
//           valueKey="id"
//           placeholder="Selecionar contato..."
//           className="w-full"
//         />
//         {errors.contact_id && (
//           <span className="text-red-500 text-sm">{errors.contact_id}</span>
//         )}
//       </div>

//       <div>
//         <label className="block text-sm font-medium mb-1">Responsável</label>
//         <DynamicCombobox
//           value={data.assignee_id}
//           onChange={(value) => setData("assignee_id", value as number)}
//           endpoint={`/inertia/accounts/${accountId}/users/search`}
//           searchKey="full_name_or_email_cont"
//           labelKey="full_name"
//           valueKey="id"
//           placeholder="Selecionar responsável..."
//           className="w-full"
//         />
//         {errors.assignee_id && (
//           <span className="text-red-500 text-sm">{errors.assignee_id}</span>
//         )}
//       </div>

//       <div>
//         <label className="block text-sm font-medium mb-1">Valor</label>
//         <input
//           type="number"
//           value={data.value}
//           onChange={(e) => setData("value", Number(e.target.value))}
//           className="w-full border rounded-lg px-3 py-2"
//         />
//       </div>

//       <button
//         type="submit"
//         disabled={processing}
//         className="bg-primary text-primary-foreground px-4 py-2 rounded-lg disabled:opacity-50"
//       >
//         {processing ? "Salvando..." : "Criar Deal"}
//       </button>
//     </form>
//   );
// }

// =============================================================================
// EXEMPLO 4: Com transformResponse customizado
// =============================================================================
export function CustomResponseExample({ accountId }: { accountId: number }) {
  const [selected, setSelected] = React.useState<number | null>(null);

  return (
    <DynamicCombobox
      value={selected}
      onChange={(value) => setSelected(value as number)}
      endpoint={`/api/v1/accounts/${accountId}/products/search`}
      searchKey="name_cont"
      labelKey="name"
      valueKey="id"
      placeholder="Buscar produto..."
      // Se a API retorna { items: [...] } em vez de { data: [...] }
      transformResponse={(response) => (response as { items: unknown[] }).items}
    />
  );
}

// =============================================================================
// EXEMPLO 5: Label customizado (combinando campos)
// =============================================================================
export function CustomLabelExample({ accountId }: { accountId: number }) {
  const [selected, setSelected] = React.useState<number | null>(null);

  return (
    <DynamicCombobox
      value={selected}
      onChange={(value, option) => {
        setSelected(value as number);
        // option contém todos os dados do registro
        if (option) {
          console.log("Selected:", option);
        }
      }}
      endpoint={`/inertia/accounts/${accountId}/contacts/search`}
      searchKey="full_name_or_email_cont"
      labelKey="full_name" // Ainda precisamos de um labelKey básico
      valueKey="id"
      placeholder="Buscar contato..."
    />
  );
}

/**
 * RANSACK SEARCH KEYS COMUNS:
 *
 * Predicados mais usados:
 * - _cont     → LIKE '%value%'
 * - _eq       → = value
 * - _start    → LIKE 'value%'
 * - _end      → LIKE '%value'
 * - _gt       → > value
 * - _lt       → < value
 * - _gteq     → >= value
 * - _lteq     → <= value
 * - _present  → IS NOT NULL AND != ''
 * - _blank    → IS NULL OR = ''
 *
 * Combinações com OR:
 * - full_name_or_email_cont → busca em full_name OU email
 * - full_name_or_email_or_phone_cont → busca em 3 campos
 *
 * Exemplos por resource:
 *
 * Contact:
 *   - full_name_cont
 *   - email_cont
 *   - phone_cont
 *   - full_name_or_email_cont
 *
 * User:
 *   - full_name_cont
 *   - email_cont
 *   - full_name_or_email_cont
 *
 * Product (se existir):
 *   - name_cont
 *   - sku_cont
 */
