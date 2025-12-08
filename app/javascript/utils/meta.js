export function getMetaJSON(name) {
  const meta = document.querySelector(`meta[name="${name}"]`);
  if (!meta || !meta.content) return null;

  try {
    return JSON.parse(meta.content);
  } catch (error) {
    console.error(`Erro ao parsear meta "${name}":`, error);
    return null;
  }
}
export function getMetaContent(name) {
  return document.querySelector(`meta[name="${name}"]`)?.content || null;
}

export function getRailsEnvironment() {
  return getMetaContent("rails-environment");
}
