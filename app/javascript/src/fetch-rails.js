import Rails from "@rails/ujs"

export default class FetchRails {
  constructor(url, body = "") {
    this.url = url
    this.body = body
    this.defaultParams = {
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": Rails.csrfToken(),
        "X-Requested-With": "XMLHttpRequest"
      },
      credentials: "same-origin"
    }
  }

  async request(method = "get", {timeout = 10000, returnResponse = false, parameters = {}} = {}) {
    const timeoutController = new AbortController()
    const timeoutID = setTimeout(() => timeoutController.abort(), timeout)

    if ("headers" in parameters) {
      parameters["headers"] = {...this.defaultParams.headers, ...parameters.headers}
    }
    const finalParams = {
      method: method,
      ...this.defaultParams,
      ...parameters,
      signal: timeoutController.signal
    }
    const response = await fetch(this.url, finalParams)
    clearTimeout(timeoutID)
    if (returnResponse) return response
    if (!response.ok) throw new Error(`${ response.status }: ${ response.statusText }`)

    const data = await response.text()
    return data
  }

  async get({timeout = 10000, returnResponse = false, parameters = {}} = {}) {
    return this.request("get", { timeout, returnResponse, parameters })
  }

  async post({timeout = 10000, returnResponse = false, parameters = {}, method = "post"} = {}) {
    parameters = {...parameters, body: JSON.stringify(this.body)}
    return this.request(method, { timeout, returnResponse, parameters })
  }
}
