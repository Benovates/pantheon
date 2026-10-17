---
tags:
  - Forms
  - Components
---

# Form

Form puts its children in a column with equal spacing. It can have a title. It grows to fit its children.

## Usage

Call `Components.Form` with a scope and a table of properties:

```luau
C.Form(scope, {
	Title = "Sign in",
	Children = {
		C.TextField(scope, { Label = "Email" }),
		C.TextField(scope, { Label = "Password" }),
		C.Button(scope, { Text = "Continue", Variant = "Filled" }),
	},
})
```

## Properties

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `Title` | `UsedAs<string>` | :x: | - | Heading above the children. |
| `Children` | `any` | :x: | - | The content of the form. |
