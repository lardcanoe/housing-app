import { GroupBase, StylesConfig } from "react-select";
import { Option } from "../../../interfaces/Option.interface";

export const selectStyles:StylesConfig<Option, boolean, GroupBase<Option>> = {
    option: (provided, state) => ({
      ...provided
    }),
    control: (provided) => ({
        ...provided,
        borderRadius: '0.5rem',
        height: '3rem',
    }),
    singleValue: (provided, state) => {
      const opacity = state.isDisabled ? 0.5 : 1;
      const transition = 'opacity 300ms';
  
      return { ...provided, opacity, transition };
    },
    multiValue: (styles, { data }) => ({
        ...styles,
        backgroundColor: "#560DF8",
        color: "white",
    }),
    multiValueLabel: (styles, { data }) => ({
        ...styles,
        color: "white",
      }),
  }
  