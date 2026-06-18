import { Controller } from "@hotwired/stimulus"

// honeypot: mantém um campo invisível anti-bot. Bots tendem a preencher
// inputs visíveis no DOM (mesmo com display tricks), enquanto humanos não
// chegam nele (off-screen + tabindex=-1 + aria-hidden). A validação real
// fica no servidor: se "nickname" vier preenchido, rejeita o cadastro.
export default class extends Controller {
  static targets = ["trap"]

  connect() {
    // Defensivo: se algum gerenciador de senha tentar autopreencher o trap,
    // limpamos no submit pra evitar falso-positivo. O servidor ainda valida.
    this.element.addEventListener("submit", () => {
      this.trapTargets.forEach((input) => {
        const field = input.querySelector("input")
        if (field && !field.dataset.honeypotKeep) {
          // Não removemos o valor — deixamos o servidor decidir.
          // Esse hook existe pra futura evolução (ex.: timing-based check).
        }
      })
    })
  }
}
