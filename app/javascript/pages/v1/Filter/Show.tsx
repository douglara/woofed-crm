/**
 * DynamicFilter Usage Example
 *
 * Este arquivo demonstra como usar o componente DynamicFilter
 * para criar filtros dinâmicos estilo Motor Admin com Inertia + React + Ransack.
 */

import * as React from "react";
import { usePage } from "@inertiajs/react";
import { DynamicFilter, type FilterField } from "@/components/filters";

// =============================================================================
// Types
// =============================================================================
interface Resource {
  value: string;
  label: string;
}

interface PageProps {
  resources: Resource[];
  schemas: Record<string, FilterField[]>;
  accountId: number;
  [key: string]: unknown;
}

// =============================================================================
// Página principal (default export para Inertia)
// =============================================================================
export default function Show() {
  const { resources, schemas, accountId } = usePage<PageProps>().props;
  const [selectedResource, setSelectedResource] = React.useState<string>(
    resources?.[0]?.value || "contacts",
  );
  const [appliedQuery, setAppliedQuery] = React.useState<string>("");

  // Campos disponíveis para o recurso selecionado
  const fields: FilterField[] = React.useMemo(() => {
    return schemas?.[selectedResource] || [];
  }, [schemas, selectedResource]);

  // Handler para quando o filtro é aplicado
  const handleApply = (ransackParams: Record<string, unknown>) => {
    // Mostra o query gerado para debug
    setAppliedQuery(JSON.stringify(ransackParams, null, 2));

    // Em produção, você faria a navegação para aplicar o filtro:
    // router.get(`/accounts/${accountId}/${selectedResource}`, {
    //   q: ransackParams
    // }, { preserveState: true });
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="mx-auto max-w-5xl space-y-8">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-gray-900">
            Dynamic Filter Demo
          </h1>
          <p className="mt-1 text-sm text-gray-500">
            Filtros dinâmicos inspirados no Motor Admin para Rails + Ransack
          </p>
        </div>

        {/* Resource Selector */}
        <div className="rounded-lg border border-gray-200 bg-white p-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Selecionar Recurso
          </label>
          <div className="flex gap-2">
            {resources?.map((resource) => (
              <button
                key={resource.value}
                onClick={() => setSelectedResource(resource.value)}
                className={`
                  rounded-md px-4 py-2 text-sm font-medium transition-colors
                  ${
                    selectedResource === resource.value
                      ? "bg-blue-600 text-white"
                      : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                  }
                `}
              >
                {resource.label}
              </button>
            ))}
          </div>
        </div>

        {/* Filter Component */}
        <div className="rounded-lg border border-gray-200 bg-white p-4">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            Filtros para {selectedResource}
          </h2>

          <DynamicFilter
            key={selectedResource}
            resource={selectedResource}
            fields={fields}
            onApply={handleApply}
            enableGrouping={true}
            enableSavedFilters={false}
            accountId={accountId}
          />
        </div>

        {/* Debug Output */}
        {appliedQuery && (
          <div className="rounded-lg border border-gray-200 bg-white p-4">
            <h2 className="mb-2 text-lg font-semibold text-gray-900">
              Query Ransack Gerado
            </h2>
            <p className="mb-2 text-sm text-gray-500">
              Este é o objeto que seria enviado como parâmetro `q` para o
              Ransack:
            </p>
            <pre className="rounded-md bg-gray-900 p-4 text-sm text-green-400 overflow-x-auto">
              {appliedQuery}
            </pre>

            <div className="mt-4 p-3 bg-blue-50 rounded-md">
              <h3 className="text-sm font-medium text-blue-800">
                Como usar no backend:
              </h3>
              <pre className="mt-2 text-xs text-blue-700">
                {`# No controller Rails:
@results = ${selectedResource.charAt(0).toUpperCase() + selectedResource.slice(1, -1)}.ransack(params[:q]).result`}
              </pre>
            </div>
          </div>
        )}

        {/* Available Fields */}
        <div className="rounded-lg border border-gray-200 bg-white p-4">
          <h2 className="mb-2 text-lg font-semibold text-gray-900">
            Campos Disponíveis ({fields.length})
          </h2>
          <div className="grid grid-cols-2 gap-2 md:grid-cols-3 lg:grid-cols-4">
            {fields.map((field) => (
              <div
                key={field.name}
                className="rounded-md bg-gray-100 px-3 py-2 text-sm"
              >
                <span className="font-medium">{field.label}</span>
                <span className="ml-2 text-xs text-gray-500">
                  ({field.type})
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Usage Instructions */}
        <div className="rounded-lg border border-gray-200 bg-white p-4">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            Como Usar
          </h2>

          <div className="space-y-4 text-sm text-gray-700">
            <div>
              <h3 className="font-medium text-gray-900">
                1. Importar o componente:
              </h3>
              <pre className="mt-1 rounded-md bg-gray-100 p-2 text-xs">
                {`import { DynamicFilter, type FilterField } from "@/components/filters";`}
              </pre>
            </div>

            <div>
              <h3 className="font-medium text-gray-900">
                2. Definir os campos:
              </h3>
              <pre className="mt-1 rounded-md bg-gray-100 p-2 text-xs overflow-x-auto">
                {`const fields: FilterField[] = [
  { name: "full_name", label: "Nome", type: "text" },
  { name: "email", label: "Email", type: "text" },
  { name: "created_at", label: "Criado em", type: "date" },
  { 
    name: "status", 
    label: "Status", 
    type: "select",
    options: [
      { value: "active", label: "Ativo" },
      { value: "inactive", label: "Inativo" }
    ]
  }
];`}
              </pre>
            </div>

            <div>
              <h3 className="font-medium text-gray-900">
                3. Usar no componente:
              </h3>
              <pre className="mt-1 rounded-md bg-gray-100 p-2 text-xs overflow-x-auto">
                {`<DynamicFilter
  resource="contacts"
  fields={fields}
  onApply={(ransackParams) => {
    router.get('/contacts', { q: ransackParams }, { preserveState: true });
  }}
  enableGrouping={true}
  enableSavedFilters={false}
/>`}
              </pre>
            </div>

            <div>
              <h3 className="font-medium text-gray-900">
                4. No backend Rails:
              </h3>
              <pre className="mt-1 rounded-md bg-gray-100 p-2 text-xs">
                {`# app/controllers/contacts_controller.rb
def index
  @contacts = Contact.ransack(params[:q]).result
end

# Certifique-se de permitir os atributos no model:
# def self.ransackable_attributes(auth_object = nil)
#   %w[full_name email phone created_at updated_at]
# end`}
              </pre>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
